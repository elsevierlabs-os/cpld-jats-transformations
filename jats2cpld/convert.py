from rdflib import Graph, Namespace, URIRef, Literal, BNode, RDF, XSD
import base64
import hashlib
import mmh3
from lxml import etree as ET

BASE = "https://data.example.com/publishing/pii/"

EDM = Namespace("https://data.elsevier.com/schema/edm/")
RV = Namespace("https://data.elsevier.com/research/schema/rv/")
NAS = Namespace("https://data.elsevier.com/publishing/schema/nas/")
IDTYPE = Namespace("https://data.elsevier.com/e/identifier/")
DOI = Namespace("http://dx.doi.org/")
ORCID = Namespace("https://orcid.org/")
SCHEMA = Namespace("https://schema.org/")
EX = Namespace("https://data.example.com/example/")


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
        g.bind('ex', EX)

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


def hash(context, text):
    hasher = hashlib.sha1(str(text).encode('utf-8'))
    hasher2 = mmh3.hash(str(text).encode('utf-8'))
    return base64.urlsafe_b64encode(hasher.digest()[:10])



def dom_from_file(filename):
    return ET.parse(filename)


def register_xslt_functions():
    """Registers Python methods inside the XSLT function namespace"""
    ns = ET.FunctionNamespace('https://data.example.com/function/')
    ns.prefix = 'f'

    gb = GraphBuilder()

    ns['add_relation'] = gb.add_relation
    ns['add_attribute'] = gb.add_attribute
    ns['register_doc_namespace'] = gb.register_doc_namespace
    ns['get_document_iri'] = gb.get_document_iri
    ns['hash'] = hash

    return gb 

def convert_from_file(filename, html_path, jsonld_path, embed=True):
    gb = register_xslt_functions()

    dom = dom_from_file(filename)
    # print(ET.tostring(dom, pretty_print=False))

    xslt = ET.parse("jats2html.xslt")
    transform = ET.XSLT(xslt)
    newdom = transform(dom)
    print(newdom)

    jsonld_data = gb.serialize()

    root = newdom.getroot()
    head = root.find('head')
    
    if embed:
        script = ET.SubElement(head, "script", attrib={"type":"application/ld+json"})
        script.text = jsonld_data
    else:
        link = ET.SubElement(head, 'link', attrib={"href": jsonld_path.name, "rel": "describedby", "type":"application/ld+json"})

    html = ET.tostring(newdom, pretty_print=False)

    with open(html_path, "wb") as f:
        f.write(html)

    with open(jsonld_path, "w") as f:
        f.write(jsonld_data)

    return


