# JATS to CP/LD and CP/LD to JATS

These are generic transformation between JATS (XML) format and CP/LD (HTML+JSON-LD) using an XSLT transformation with some function extensions in Python to write to or read from an RDF graph.

The scripts are both commandline Python script that can be run to convert locally stored files

- `jats-to-cpld.py` converts locally stored JATS XML files to CP/LD
- `cpld-to-jats.py` convert locally stored CP/LD files to JATS XML

## Background
This code accompanies the paper presented at JATS-Con 2025, see [here](https://ncbi.nlm.nih.gov/books/NBK611677/) for the official publication.

* The JATS XML source of this paper can be found [here](examples/roundtripping-cpld-and-jats-JATSCon-2025.xml).
* The automatically generated CP/LD version is [here](examples/roundtripping-cpld-and-jats-JATSCon-2025.html). This includes the JSON-LD graph.
* A separate JSON-LD file, with just the graph, is available [here](examples/roundtripping-cpld-and-jats-JATSCon-2025.jsonld).

You can view the CP/LD output using the [VSCode CP/LD viewer](https://marketplace.visualstudio.com/items?itemName=Elsevier.cpld-viewer).

## License and Copyright
All resources in this repository are Copyright (c) 2025 Elsevier, with special thanks to Edgar Schouten, Charles O'Connor and Rinke Hoekstra.

Exceptions are documented in [NOTICE.MD](NOTICE.MD).

The code in this repository is released under the MIT License. See [LICENSE](LICENSE).

The XML, HTML and JSON-LD sources of the paper are available under the [CC-BY 4.0 License](https://creativecommons.org/licenses/by/4.0/).

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

**NB** The CP/LD to JATS transformation is not complete yet, but is sufficiently mature to illustrate the principles.

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
