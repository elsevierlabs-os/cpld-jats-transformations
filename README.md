# JATS to CP/LD and CP/LD to JATS

These are generic transformation between JATS (XML) format and CP/LD (HTML+JSON-LD) using an XSLT transformation with some function extensions in Python to write to or read from an RDF graph.

The scripts are both commandline Python script that can be run to convert locally stored files

- `jats-to-cpld.py` converts locally stored JATS XML files to CP/LD
- `cpld-to-jats.py` convert locally stored CP/LD files to JATS XML


## How to run
Make sure you have `poetry` installed.

Run `poetry install`.

## XSLT

Both XSLT transformation make use of some function extensions in Python to write to or read from an RDF graph.

- `jats2html.xslt` contains the templats converting from JATS to HTML and JSON-LD
- `html2jats.xslt` contains the templats converting from HTML and JSON-LD to JATS

### Running `jats-to-cpld.py` from the commandline

Run `poetry run python jats-to-cpld.py [OPTIONS] PATHS...` 

```
Usage: jats-to-cpld.py [OPTIONS] PATHS...

  jats-to-cpld.py PATHS

  Convert al files in PATHS from JATS XML to CP/LD, and write them to a
  destination folder ('cpld' by default)

Options:
  --destination TEXT             The destination path for the CP/LD output
                                 files, defaulting to `cpld`
  --relative / --absolute        Create the destination path relative to each
                                 source file (default) or create it as is.
  --embed / --link               Embed the JSON-LD output inside the HTML file
                                 (default) or only link to it.
  --overwrite / --skip-existing  Skip existing files (default) or overwrite
                                 files without asking.
  --help                         Show this message and exit.
```

### Running `cpld-to-jats.py` from the commandline

Run `poetry run python cpld-to-jats.py [OPTIONS] PATHS...` 

```
Usage: cpld-to-jats.py [OPTIONS] PATHS...

  cpld-to-jats.py PATHS

  Convert al files in PATHS from CP/LD to JATS XML, and write them to a
  destination folder ('jats' by default)

Options:
  --destination TEXT             The destination path for the JATS output
                                 files, defaulting to `jats`
  --relative / --absolute        Create the destination path relative to each
                                 source file (default) or create it as is.
  --overwrite / --skip-existing  Skip existing files (default) or overwrite
                                 files without asking.
  --help                         Show this message and exit.
```
