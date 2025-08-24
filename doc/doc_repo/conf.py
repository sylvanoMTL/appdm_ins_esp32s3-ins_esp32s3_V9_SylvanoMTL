# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'appDM_ins_esp32s3'
html_short_title = "appDM_ins_esp32s3"
copyright = '2023, Sysrox'
author = 'Sysrox'
release = '0.0'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = []

templates_path = ['_templates']
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']



# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output
html_theme = 'furo'
html_static_path = ['_static']
html_logo = "_static/images/Logo.png"
html_favicon = '_static/images/favicon.ico'
pygments_style = "one-dark"
pygments_dark_style = "one-dark"
html_theme_options = {
    "announcement": '<a href="https://doc.sysrox.com"><img src="_static/images/house-solid.svg" alt="Home"><em><span style="vertical-align: 0.25em;">   <b>  Home documentation</b></span></em></a>',
    "light_css_variables": {
        "color-foreground-primary": "#334051", # for main text and headings,
        # "color-foreground-secondary": "#bb7cd7", # for function return type for example
        # "color-problematic": "#74ade9", # for functions names

        "color-announcement-background": "#f8f9fb",
        "color-announcement-text": "#334051",

        "color-brand-primary": "#3977be", # for link in left menu
        "color-brand-content": "#3977be", # toc menu in content

        "color-api-background": "#292c33",
        "color-api-overall": "#bb7cd7",
        "color-api-name": "#74ade9", # for functions names
        "color-api-paren": "#bb7cd7", # for parenthesis

        # Table of Contents (right)
        "color-toc-item-text": "#334051",

        # Fonts
        # "font-stack": "Segoe UI",
        # "font-stack--monospace": "SFMono-Regular",
    },
    "dark_css_variables": {
        # "color-foreground-secondary": "#bb7cd7", # for function return type for example
        # "color-problematic": "#74ade9", # for functions names

        "color-announcement-background": "#1a1c1e",
        "color-announcement-text": "#eeebee",
    },
}


extensions = ['breathe']
breathe_projects = {'appDM_ins_esp32s3': './doxyfiles/xml'}
breathe_default_project = 'appDM_ins_esp32s3'