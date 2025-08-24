# This script is made to be executed by CI.
# It will repo sync master project from developpement server, remove some files, build some static libraries and push them user deployement server.
# Pio env should be sourced before executing this script.

from git import Repo
import git
import os, shutil
import glob
import fileinput
import re
import yaml
import configparser
import copy


class bcolors:
    HEADER = "\033[95m"
    OKBLUE = "\033[94m"
    OKCYAN = "\033[96m"
    OKGREEN = "\033[92m"
    WARNING = "\033[93m"
    FAIL = "\033[91m"
    ENDC = "\033[0m"
    BOLD = "\033[1m"
    UNDERLINE = "\033[4m"


default_branch = "main"

commiter_name = "CI_runner"
commiter_email = "ci_runner@sysrox.com"

destination_server = "git.sysrox.com"

repo_adress_manifest = "https://git.sysrox.com/code/manifests/manifest_ins.git"
manifest_branch = "main"

runner_ci_token = os.environ["runner_ci_token"]
runner_ci_token_main = os.environ["runner_ci_token_main"]
tag = os.environ["CI_COMMIT_TAG"]


class IndentDumper(yaml.Dumper):
    def increase_indent(self, flow=False, indentless=False):
        return super(IndentDumper, self).increase_indent(flow, False)


class MOVE_REPO:
    def __init__(self):
        # os.environ["runner_ci_token"] = runner_ci_token
        # os.environ["runner_ci_token_main"] = runner_ci_token_main
        # TODO: remove and create git user
        pass

    def clone_repo(self, adress):
        if os.path.exists("repo"):
            repo = Repo("repo")
            return repo

        return Repo.clone_from(adress, "repo")

    def repo_sync(self, adress, branch=None):
        # Replace token for repo init
        for i in range(len(adress)):
            if adress[i] == "/" and adress[i + 1] == "/":
                adress = (
                    adress[: i + 2] + "gitlab-ci-token:" + runner_ci_token + "@" + adress[i + 2 :]
                )
                break

        if os.path.exists("lib") and os.path.exists("src"):
            print(
                f"{bcolors.WARNING}Lib and src folders already exists. No need to repo sync.",
                bcolors.ENDC,
            )
            return

        # Clone repo
        if not os.path.exists("manifest"):
            Repo.clone_from(adress, "manifest", branch=manifest_branch)

        # Repo sync with manifest
        if branch == None:
            branch = default_branch
            os.system("repo init -u " + adress)
        else:
            os.system("repo init -u " + adress + " -b " + branch)

        # Replace token in manifests (default_ci, lib_ci and src_ci)
        with open(".repo/manifests/default_ci.xml", "r") as file:
            filedata = file.read()
            filedata = filedata.replace("{runner_ci_token}", runner_ci_token)

        with open(".repo/manifests/default_ci.xml", "w") as file:
            file.write(filedata)

        with open(".repo/manifests/lib_ci.xml", "r") as file:
            filedata = file.read()
            filedata = filedata.replace("{runner_ci_token}", runner_ci_token)

        with open(".repo/manifests/lib_ci.xml", "w") as file:
            file.write(filedata)

        with open(".repo/manifests/src_ci.xml", "r") as file:
            filedata = file.read()
        filedata = filedata.replace("{runner_ci_token}", runner_ci_token)

        with open(".repo/manifests/src_ci.xml", "w") as file:
            file.write(filedata)

        os.system("repo sync --no-clone-bundle -m default_ci.xml")

    def get_repo(self, adress):
        repo = None
        if os.path.exists(adress):
            repo = Repo(adress)

        return repo

    def get_all_repos_recursive(self, folder_list=None):
        repos = []
        if folder_list == None:
            folder_list = "."

        for folder in folder_list:
            # Recursively search for .git folders and execute get_repo on the parent folder
            for root, dirs, files in os.walk(folder, topdown=True):
                for dir in dirs:
                    if dir == ".git":
                        repos.append(self.get_repo(root))

        return repos

    def execute_ci(self, repos_list=None):
        if repos_list == None:
            return

        print(
            f"{bcolors.HEADER}Building code for individual folders ",
            bcolors.ENDC,
        )

        base_path = os.getcwd()
        for repo in repos_list:
            last_path = os.path.basename(os.path.normpath(os.path.dirname(repo.working_dir)))
            if last_path == "lib":
                if os.path.exists(repo.working_dir + "/build.sh"):
                    print(
                        f"{bcolors.HEADER}Building code for",
                        repo.working_dir + bcolors.ENDC,
                    )
                    # Build esp32-s3
                    os.chdir(repo.working_dir)
                    res = os.system("./build.sh lolin_s3_ci")
                    if res != 0:
                        print("Error while building esp32-s3 for package " + repo.working_dir)
                        return False

                    os.chdir(base_path)
                else:
                    print(
                        f"{bcolors.WARNING}No build.sh found in",
                        repo.working_dir + bcolors.ENDC,
                    )
            elif last_path == "src":
                print(
                    f"{bcolors.HEADER}Building code for source folder: ",
                    repo.working_dir + bcolors.ENDC,
                )
                # Build esp32-s3
                print(
                    f"{bcolors.WARNING}Removing cpp files libDM_SRX_INS_10_DOF for representative user build",
                    bcolors.ENDC,
                )

                files_to_delete = glob.glob("lib/libDM_SRX_INS_10_DOF/src/*.cpp")
                for file_path in files_to_delete:
                    os.remove(file_path)
                if os.path.exists("lib/libDM_SRX_INS_10_DOF/src/model"):
                    shutil.rmtree("lib/libDM_SRX_INS_10_DOF/src/model")

                print(
                    f"{bcolors.WARNING}Removing cpp files libDM_SRX_fft for representative user build",
                    bcolors.ENDC,
                )

                for root, dirs, files in os.walk("lib/libDM_SRX_fft/src"):
                    for file in files:
                        if file.endswith(".cpp") or file.endswith(".h"):
                            file_path = os.path.join(root, file)
                            os.remove(file_path)

                res = os.system("pio run -c src/appDM_ins_esp32s3/conf/conf.ini -e lolin_s3")

                if res != 0:
                    print(
                        f"{bcolors.FAIL}Error while building esp32-s3 for package ",
                        repo.working_dir + bcolors.ENDC,
                    )

                    return False

    def create_artifacts(self, repos):
        # Remove symbolic link and copy content of linked folder to target folder
        for repo in repos:
            gitPath = os.path.join(repo.working_dir, ".git")
            gitPath2 = os.path.join(repo.working_dir, ".git2")
            if os.path.islink(gitPath):
                # Copy content
                link_abs_path = os.path.join(os.path.dirname(gitPath), os.readlink(gitPath))
                shutil.copytree(link_abs_path, gitPath2)
                # Remove symbolic link
                os.unlink(gitPath)
                # Rename folder
                os.rename(gitPath2, gitPath)

            # remove files not followed by git ignore
            docRepoPath = os.path.join(repo.working_dir, "doc", "doc_repo")
            shutil.rmtree(os.path.join(docRepoPath, "_build"), ignore_errors=True)
            shutil.rmtree(os.path.join(docRepoPath, "doxyfiles"), ignore_errors=True)
            shutil.rmtree(os.path.join(docRepoPath, "_static", "doxyfiles"), ignore_errors=True)

        # Create artifact folder. A call to execute_ci has to be done before
        os.makedirs("artifacts", exist_ok=True)
        os.makedirs("artifacts/flashable_files", exist_ok=True)
        os.makedirs("artifacts/code", exist_ok=True)
        os.makedirs("artifacts/manifest", exist_ok=True)

        os.system("cp -r .pio/build/lolin_s3/*.bin artifacts/flashable_files")
        os.system(
            "cp ~/.platformio/packages/framework-arduinoespressif32/tools/partitions/boot_app0.bin artifacts/flashable_files"
        )
        # Copy flash scripts
        repoSrc = self.get_all_repos_recursive(["src"])
        idxRepo = 0
        curLen = 100000
        for i in range(len(repoSrc)):
            if len(repoSrc[i].working_dir) < curLen:  # take shotest path to avoid nested git repos
                curLen = len(repoSrc[i].working_dir)
                idxRepo = i
        srcRepoPath = os.path.join(repoSrc[idxRepo].working_dir, "tools")
        shutil.copyfile(
            os.path.join(srcRepoPath, "flash_esp_files.sh"),
            "artifacts/flashable_files/flash_esp_files.sh",
        )
        # Copy code folders
        os.system("cp -r lib artifacts/code")
        os.system("cp -r src artifacts/code")
        os.system("cp -r manifest/ artifacts/manifest/")

        # Reset hard each repo to avoid uncommitted changes (I do not know why they are here)
        reposArtifact = self.get_all_repos_recursive(
            ["artifacts/code/lib", "artifacts/code/src", "artifacts/manifest"]
        )
        for repo in reposArtifact:
            repo.git.reset("--hard")
            # Delete tokens for artifacts
            remote_url = repo.remotes[0].config_reader.get("url")
            idxFirst = remote_url.find("//")
            idxSecond = remote_url.find("@")
            newRemoteUrl = remote_url[: idxFirst + 2] + remote_url[idxSecond + 1 :]
            remote_name = repo.remotes[0].name
            repo.git.remote("remove", remote_name)
            repo.git.remote("add", remote_name, newRemoteUrl)
            print(
                f"{bcolors.OKGREEN}Remote replaced in artifacts with ", newRemoteUrl + bcolors.ENDC
            )

        # Compress folder
        shutil.make_archive("artifacts", "zip", "artifacts")

        # shutil.rmtree(".pio")

    def commit_modifs(self, repos_list):
        base_dir = os.getcwd()
        for i in range(len(repos_list)):
            os.chdir(repos_list[i].working_dir)

            # Set identity:
            os.system("git config user.name " + commiter_name)
            os.system("git config user.email " + commiter_email)

            # Reinit git for model
            baseName = os.path.basename(repos_list[i].working_dir)
            if (
                baseName == "libDM_SRX_INS_10_DOF"
                or baseName == "manifest"
                or baseName == "libDM_SRX_fft"
            ):  # All branched repos
                # Save remote
                remote_url = repos_list[i].remotes[0].config_reader.get("url")
                remote_name = repos_list[i].remotes[0].name
                try:
                    os.remove(".git")
                except:
                    # It is a folder
                    shutil.rmtree(".git")
                # Reinit git
                repos_list[i].git.init("-b", "main")
                # Set identity:
                os.system("git config user.name " + commiter_name)
                os.system("git config user.email " + commiter_email)
                repos_list[i].git.add(".")
                repos_list[i].git.commit("-m", "Release " + tag)
                repos_list[i].git.remote("add", remote_name, remote_url)
            else:
                # Check if there is something to commit
                hcommit = repos_list[i].head.commit
                curDiff = hcommit.diff(None)
                if len(curDiff) != 0:
                    repos_list[i].git.add(".")
                    repos_list[i].git.commit("-m", "Release " + tag)
                    print(
                        f"{bcolors.OKGREEN}Commited modifs for",
                        os.path.basename(repos_list[i].working_dir) + bcolors.ENDC,
                    )
                else:
                    print(
                        f"{bcolors.WARNING}Nothing to commit in ",
                        repos_list[i].working_dir + bcolors.ENDC,
                    )

            os.chdir(base_dir)

    def add_tag(self, tag, repos_list):
        base_dir = os.getcwd()
        for i in range(len(repos_list)):
            os.chdir(repos_list[i].working_dir)

            try:
                repos_list[i].git.tag(tag)
                print(
                    f"{bcolors.OKGREEN}Successfully add tag ",
                    tag,
                    " to ",
                    os.path.basename(repos_list[i].working_dir) + bcolors.ENDC,
                )
            except:
                print(
                    f"{bcolors.FAIL}Failed to add tag ",
                    tag,
                    " to ",
                    os.path.basename(repos_list[i].working_dir),
                    bcolors.ENDC,
                )

            os.chdir(base_dir)

    def build_doc(self, repos_list):
        base_dir = os.getcwd()
        for i in range(len(repos_list)):
            os.chdir(repos_list[i].working_dir)

            try:
                if os.path.exists("doc") and os.path.exists("generate_doc.sh"):
                    os.system("./generate_doc.sh true ci")  # TODO: true ci
                    print(
                        f"{bcolors.OKGREEN}Successfully build doc for ",
                        os.path.basename(repos_list[i].working_dir) + bcolors.ENDC,
                    )
                    # Remove use template
                    shutil.rmtree("doc/libDM_doc_template")
                    # Remove doxygen files
                    os.system("rm -rf doxygen*")
                else:
                    print(
                        f"{bcolors.WARNING}No doc folder or script found in ",
                        os.path.basename(repos_list[i].working_dir) + bcolors.ENDC,
                    )
            except:
                print(
                    f"{bcolors.FAIL}Failed to build doc for ",
                    os.path.basename(repos_list[i].working_dir),
                    bcolors.ENDC,
                )

            os.chdir(base_dir)

    def package_doc(self, repos_list):
        if os.path.exists("doc"):
            shutil.rmtree("doc")

        os.mkdir("doc")
        for i in range(len(repos_list)):
            doc_source_path = os.path.join(
                repos_list[i].working_dir, "doc", "doc_repo", "_build", "html"
            )
            script_path = os.path.join(repos_list[i].working_dir, "generate_doc.sh")
            if not os.path.exists(doc_source_path) or not os.path.exists(script_path):
                continue

            doc_path = os.path.join("doc", os.path.basename(repos_list[i].working_dir)).lower()
            shutil.copytree(doc_source_path, doc_path)

        shutil.make_archive("doc", "zip", "doc")


if __name__ == "__main__":
    print(
        f"{bcolors.OKCYAN}Will deploy tag ",
        tag,
        "to ",
        destination_server + bcolors.ENDC,
    )
    moverRepo = MOVE_REPO()
    moverRepo.repo_sync(repo_adress_manifest, manifest_branch)

    # For normal repos, just execute CI script
    repos = moverRepo.get_all_repos_recursive(["lib", "src", "manifest"])
    moverRepo.execute_ci(repos)
    moverRepo.build_doc(repos)
    moverRepo.package_doc(repos)
    moverRepo.commit_modifs(repos)
    moverRepo.add_tag(tag, repos)
    moverRepo.create_artifacts(repos)
