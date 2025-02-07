from rdflib import Graph, Namespace, URIRef, Literal, BNode, RDF, XSD
from bs4 import BeautifulSoup
from lxml import etree as ET
import subprocess

BASE = "https://data.example.com/publishing/pii/"

EDM = Namespace("https://data.elsevier.com/schema/edm/")
RV = Namespace("https://data.elsevier.com/research/schema/rv/")
NAS = Namespace("https://data.elsevier.com/publishing/schema/nas/")
IDTYPE = Namespace("https://data.elsevier.com/e/identifier/")
DOI = Namespace("http://dx.doi.org/")
ORCID = Namespace("https://orcid.org/")
SCHEMA = Namespace("https://schema.org/")


class GraphBuilder(object):

    def __init__(self):
        # Initialize the graph without identifier, just in case register_namespace is not called as the first function in the XSLT
        self.g = self.initialize_graph()

    def initialize_graph(self, identifier=None):
        g = Graph(identifier=identifier)
        g.bind('edm', EDM)
        g.bind('rv', RV)
        g.bind('nas', NAS)
        g.bind('idtype', IDTYPE)
        g.bind('doi', DOI)
        g.bind('orcid', ORCID)
        g.bind('schema', SCHEMA)

        return g

    def register_doc_namespace(self, context, pii):
        self.document_iri = f"{BASE}{pii}"

        DOC = Namespace(f"{BASE}{pii}#")


        self.g = self.initialize_graph(self.document_iri)

        self.g.bind('doc',DOC)
        
        return ""

    def expand(self,curie):
        # Try to expand, if not, assume it's a full IRI
        try:
            return self.g.namespace_manager.expand_curie(str(curie))
        except:
            return URIRef(curie)

    def add_relation(self, context, s,p,o):
        self.g.add((self.expand(s),self.expand(p),self.expand(o)))
        return ""

    def find_type(self, context, s,p,o):
        if str(s) == "":
            # Pass, as there is no value
            return ""

        if d is not None:
            self.g.add((self.expand(s),self.expand(p),Literal(o, datatype=self.expand(d))))
        else:
            self.g.add((self.expand(s),self.expand(p),Literal(o)))
        return ""

    def add_attribute(self, context, s,p,o, d=None):
        if str(o) == "":
            # Pass, as there is no value
            return ""

        if d is not None:
            self.g.add((self.expand(s),self.expand(p),Literal(o, datatype=self.expand(d))))
        else:
            self.g.add((self.expand(s),self.expand(p),Literal(o)))
        return ""

    def get_document_iri(self,context):
        return self.document_iri 

    def serialize(self):
        return self.g.serialize(format="json-ld", auto_compact=True)
    
    def get_entity_properties(self, context):
        return ""


def dom_from_file(filename):
    return ET.parse(filename)


def register_xslt_functions():
    """Registers Python methods inside the XSLT function namespace"""
    ns = ET.FunctionNamespace('https://data.example.com/function/')
    ns.prefix = 'f'

    gb = GraphBuilder()

    ns['add_relation'] = gb.add_relation
    ns['find_type'] = gb.find_type
    ns['add_attribute'] = gb.add_attribute
    ns['register_doc_namespace'] = gb.register_doc_namespace
    ns['get_document_iri'] = gb.get_document_iri
    return gb 


def convert_from_file(filename, jats_path):
    gb = register_xslt_functions()
    print("====================================")
    dom = dom_from_file(filename)
    soup = BeautifulSoup(ET.tostring(dom, pretty_print=False), 'html.parser')
    print(soup.prettify())

    # Find the script block with type 'application/ld+json' or else the link block with type 'application/ld+json'
    # <script type="application/ld+json">...</script> (embedded JSON-LD)
    # <link type="application/ld+json" rel="preload" href="..."/> (external JSON-LD)
    script_tag = soup.find('script', {'type': 'application/ld+json'})
    link_tag = soup.find('link', {'type': 'application/ld+json'})
    if script_tag:
        jsonld = script_tag.string
        gb.g.parse(data=jsonld, format="json-ld")
        print("JSON-LD found embedded in the HTML file")
        print("-------------------------------------")
    else:
        if link_tag:
            jsonld_file = link_tag.get('href')
            if jsonld_file:
                response = requests.get(jsonld_file)
                if response.status_code == 200:
                    jsonld_data = json.loads(response.text)
                    gb.g.parse(data=jsonld_data, format="json-ld")
                    print("JSON-LD found in a external file linked in the HTML file")
                else:
                    jsonld_data = None
                    print(f"Referenced file not found. (error {response.status_code})")
            else:
                jsonld_data = None
                print("No JSON-LD found in the HTML file")




    # print(ET.tostring(dom, pretty_print=False))

    xslt = ET.parse("html2jats.xslt")
    transform = ET.XSLT(xslt)
    tree = ET.ElementTree(element=ET.fromstring(soup.prettify().encode('utf-8')))
    lxml_root = ET.fromstring(str(soup).encode('utf-8'))
    
    # Print the length of the string representation of lxml_root
    print(len(ET.tostring(lxml_root, pretty_print=True).decode('utf-8')))

    #newdom = transform(lxml_root)
    #print(newdom)

    # xml = ET.tostring(newdom, pretty_print=True).decode('utf-8')

    #with open(jats_path, "w") as f:
    #    f.write(xml)

    saxon_jar_path = "/Users/schoutened/Downloads/SaxonHE12-5J/saxon-he-12.5.jar"  # Update this path to your Saxon JAR file
    command = [
        "java", "-jar", saxon_jar_path,
        "-s:" + str(filename),
        "-xsl:" + 'html2jats.xslt',
        "-o:" + str(jats_path)
    ]
    print(command)
    subprocess.run(command, check=True)

    
    
    return


