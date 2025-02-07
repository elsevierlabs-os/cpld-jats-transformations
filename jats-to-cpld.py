import click
from pathlib import Path
import os
from jats2cpld import convert

@click.command()
@click.argument('PATHS', required=True, nargs=-1, type=click.Path(exists=True))
@click.option('--destination', default="cpld", help='The destination path for the CP/LD output files, defaulting to `cpld` ')
@click.option('--relative/--absolute', default=True, help='Create the destination path relative to each source file (default) or create it as is.')
@click.option('--embed/--link', default=True, help='Embed the JSON-LD output inside the HTML file (default) or only link to it.')
@click.option('--overwrite/--skip-existing', default=False, help='Skip existing files (default) or overwrite files without asking.')
def cli_convert(paths, destination, relative, embed, overwrite):
    """jats-to-cpld.py PATHS
    
    Convert al files in PATHS from JATS XML to CP/LD,
    and write them to a destination folder ('cpld' by default)
    """
    for jats_file in paths:
        jats_path = Path(jats_file)
        jats_path_stem = jats_path.stem

        if relative:
            destination_path = jats_path.parent.joinpath(Path(destination))
        else:
            destination_path = Path(destination)
        
        # Create the destination if it doesn't already exist.
        destination_path.mkdir(parents=True, exist_ok=True)

        html_path = destination_path.joinpath(jats_path_stem + '.html')
        if not overwrite and html_path.exists:
            print(f"Destination HTML file {html_path} already exists. Continuing will overwrite the existing file.")
            if not click.confirm('Do you want to continue?'):
                print(f"Skipping conversion of {jats_path}")
                continue

        jsonld_path = destination_path.joinpath(jats_path_stem + '.jsonld')
        if not overwrite and jsonld_path.exists:
            print(f"Destination JSON-LD file {jsonld_path} already exists. Continuing will overwrite the existing file.")
            if not click.confirm('Do you want to continue?'):
                print(f"Skipping conversion of {jats_path}")
                continue

        print(f"Converting {jats_path} to destination {destination_path}")
        convert.convert_from_file(jats_path, html_path, jsonld_path, embed=embed)
        print(f"... done")


    
if __name__ == '__main__':
    cli_convert()
