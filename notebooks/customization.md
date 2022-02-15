# Customizing Notebook Preferences

You might want to customize preferences in JupyterLab, e.g. 
adding line numbers to code cells in notebooks or to activate 
code folding in the text editor. This article explains how you 
can persist those changes, so they will be loaded automatically 
every time you start a new notebook server.

## Background

In JupyterLab, users can add User Preferences in the Advanced 
Settings Editor (Settings → Advanced Settings Editor). These 
override the System Defaults and are stored in JSON-files at 
`~/.jupyter/lab/user-settings/`. The System Defaults on the 
left hand side show all available options with their default 
values. They can be used to write valid User Preferences on 
the right hand side. The lower right corner informs about 
erroneous settings. You can find the correct file-names in the 
comment on top of the corresponding System Defaults.

The key idea is to add JSON-files with User Preferences 
automatically using the Dockerfile for the project image.

## Instructions

These instructions describe the basic steps to persist User 
Preferences in the notebook image. The following section gives 
a complete example.

1.  Open the Advanced Settings Editor and modify the User Preferences.

2.  Add a script to the Dockerfile at root-level of your project’s 
    git-repository with RUN, ideally using the root user.

    a.  Create all required directories with `mkdir -p`.

    b.  Append the User Preferences to the desired file with `echo` and `>>`.

3.  Commit the Dockerfile with a semantic commit message (e.g., build()) 
    to build a new notebook image.

## Example

In this section, we want to use the instructions from above and 
apply them into practice. Let’s adapt our text editor by adding 
a vertical ruler after 80 characters and activating code folding. 
Therefore, we use the Advanced Settings Editor to write the 
following User Preferences.

```json
{'editorConfig': {'rulers': [80], 'codeFolding': true}}
```

Usually, you might want to add some line breaks and indentations 
to make the JSON-file more readable, but a one-liner is feasible 
for our purpose. We can find the correct name for our JSON-file 
in the comment on top of the corresponding System Defaults. We 
just need to replace the `:` with a `/` in the next steps.

```json
{
  // Text Editor
  // @jupyterlab/fileeditor-extension:plugin
... }
```

Let’s open the Dockerfile on root-level of out project’s git-repository 
and add the following lines after `USER root`.

```Dockerfile
USER root
...
RUN mkdir -p ~/.jupyter/lab/user-settings/@jupyterlab/fileeditor-extension/ &&
    echo "{'editorConfig': {'rulers': [80], 'codeFolding': true}}" >> ~/.jupyter/lab/user-settings/@jupyterlab/fileeditor-extension/plugin.jupyterlab-settings
...
```

Let’s recap that `~/.jupyter/lab/user-settings/` is the directory that 
holds JSON-files with user settings that override JupyterLab’s defaults. 
We add the directory @jupyterlab/fileeditor-extension/ there and append 
our modified settings to the file `plugin.jupyterlab-settings`.

Finally, we commit our changes with the semantic commit message 
`build(): modify preferences for text editor in JupyterLab`. Once the 
pipeline built the new notebook image, we can start new servers with 
our modified settings.