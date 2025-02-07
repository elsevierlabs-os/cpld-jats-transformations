# JATS to CP/LD

This is a generic transformation from JATS XML format, using an XSLT transformation with some function extensions in Python to build an RDF graph.

The `jats2cpld.py` is a commandline python script that can be run to convert locally stored JATS XML files.

## How to run
Make sure you have `poetry` installed.

Run `poetry install`.

### Running from the Commandline

Run `poetry run python jats2cpld.py [OPTIONS] PATHS...` 

```
Usage: jats2cpld.py [OPTIONS] PATHS...

  jats2cpld.py PATHS

  Convert al files in PATHS from JATS XML to CP/LD, 
  and write them to a destination folder ('output' by default)

Options:
  --destination TEXT             The destination path for the CP/LD output
                                 files
  --relative / --absolute        Create the destination path relative to each
                                 source file (default) or create it as is.
  --embed / --link               Embed the JSON-LD output inside the HTML file
                                 (default) or only link to it.
  --overwrite / --skip-existing  Skip existing files (default) or overwrite
                                 files without asking.
  --help                         Show this message and exit.
```

## XSLT

The `jats2html.xslt` contains the stylesheet that has the templates that handle the conversion from JATS to HTML and JSON-LD