<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
    xmlns:mml="http://www.w3.org/1998/Math/MathML"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:ex="http://data.example.com/example/"
    xmlns:f="https://data.example.com/function/"
    exclude-result-prefixes="f mml xsi xlink ex"
    version="3.0"
    expand-text="yes">

    <!-- ======================
        | Generic helper template `produce_id`
        purpose: to produces a value to use for the id-attribute, whether or not there was an id present on the original element
    -->
    <xsl:template name="produce_id">
        <xsl:choose>
            <xsl:when test="@id">
                <xsl:value-of select="@id"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="generate-id(.)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    
    <xsl:template match="article">
        <!-- register_namespace MUST be called as the first function in order for the RDF Graph to be initialized with an IRI rather than a BNode -->
        <xsl:apply-templates select="front/article-meta/article-id" mode="register_namespace"/>
        <xsl:value-of select="f:add_relation(f:get_document_iri(),'rdf:type','schema:ScholarlyArticle')"/>   
        <xsl:value-of select="f:add_attribute(f:get_document_iri(),'schema:title',string(article-meta/title-group/article-title))"/>
        <xsl:text disable-output-escaping='yes'>&lt;!DOCTYPE html&gt;</xsl:text>
        <xsl:element name="html">
            <xsl:attribute name="lang">
                <xsl:value-of select="@xml:lang"/>
            </xsl:attribute>
            <head>
                <meta name="generator" content="https://github.com/elsevier-centraltechnology/architecture-jats-to-cpld"/>
                <xsl:element name="meta" inherit-namespaces="no">
                    <xsl:attribute name="name">
                        <xsl:value-of select="'id'"/>
                    </xsl:attribute>
                    <xsl:attribute name="content">
                        <xsl:value-of select="f:get_document_iri()"/>
                    </xsl:attribute>
                </xsl:element>
                <title>
                    <xsl:value-of select="front/article-meta/title-group/article-title"/>
                </title>
            </head>
            <body>
                <header>
                    <xsl:apply-templates select="front"/>
                    <!--<xsl:apply-templates select="front/article-meta/article-id" mode="document_identifier"/>-->
                </header>
                <xsl:apply-templates select="body" />
                <xsl:apply-templates select="back"/>
            </body>
        </xsl:element>
    </xsl:template>

    

    <!-- ================
         | Article Metadata
    -->
    <xsl:template match="article-meta">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="journal-meta">
        <xsl:variable name="id">
            <xsl:call-template name="produce_id"/>
        </xsl:variable>
        <xsl:variable name="journalid" select="journal-id[@journal-id-type='publisher']"/>
        <xsl:variable name="journaltitle" select="journal-title-group/journal-title"/>
        <xsl:variable name="work_iri" select="concat('doc:work_',f:hash(string($id)))"/>
        <xsl:variable name="work_issn" select="string(issn)"/>
        
        <xsl:value-of select="f:add_relation(f:get_document_iri(),'schema:partOf',$work_iri)"/>
        <xsl:value-of select="f:add_relation( $work_iri, 'rdf:type',     'schema:Periodical')"/>
        <xsl:value-of select="f:add_attribute($work_iri, 'schema:title', string($journaltitle))"/> 
        <xsl:value-of select="f:add_attribute($work_iri, 'schema:issn', $work_issn)"/> 
    </xsl:template>


    <xsl:template match="//article-meta/article-id" mode="register_namespace">
        <xsl:value-of select="f:register_doc_namespace(string(.))"/>
    </xsl:template>

    <xsl:template match="//article-meta/article-id" mode="document_identifier">
        <!-- <base href="{f:get_document_iri()}"/> -->
        <meta name="id" content="{f:get_document_iri()}"/>
    </xsl:template>

    <xsl:template match="article-title">
        <xsl:variable name="id">
            <xsl:call-template name="produce_id"/>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="parent::mixed-citation|parent::element-citation">
                <span id="{$id}" class="{name()}">
                    <xsl:apply-templates/>
                </span>
            </xsl:when>
            <xsl:otherwise>
                <h1 id="{$id}" class="{name()}">
                    <xsl:apply-templates/>
                </h1>
                <xsl:value-of select="f:add_attribute(f:get_document_iri(),'schema:title',string(.))"/>
                <xsl:value-of select="f:add_relation(concat('doc:',$id),'rdf:type','nas:Title')"/>
                <xsl:value-of select="f:add_relation(f:get_document_iri(),'schema:hasPart',concat('doc:',$id))"/>                
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <xsl:template match="pub-date">
        <xsl:call-template name="metadata-labeled-entry">
            <xsl:with-param name="label">
                <xsl:text>Publication date</xsl:text>
                <xsl:call-template name="append-pub-type"/>
            </xsl:with-param>
            <xsl:with-param name="contents">
                <xsl:call-template name="format-date"/>
            </xsl:with-param>
        </xsl:call-template>
        <xsl:value-of select="f:add_attribute(f:get_document_iri(),'schema:datePublished',concat(string(year),'-',substring(concat('0',string(month)),2),'-',substring(concat('0',string(day)),2)))"/>
    </xsl:template>
    
    <xsl:template name="metadata-labeled-entry">
        <xsl:param name="label"/>
        <xsl:param name="contents">
            <xsl:apply-templates/>
        </xsl:param>
        <xsl:call-template name="metadata-entry">
            <xsl:with-param name="contents">
                <xsl:if test="normalize-space(string($label))">
                    <span class="generated">
                        <xsl:copy-of select="$label"/>
                        <xsl:text>: </xsl:text>
                    </span>
                </xsl:if>
                <xsl:copy-of select="$contents"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    
    
    <xsl:template name="metadata-entry">
        <xsl:param name="contents">
            <xsl:apply-templates/>
        </xsl:param>
        <p class="metadata-entry">
            <xsl:copy-of select="$contents"/>
        </p>
    </xsl:template>
    
    <xsl:template name="append-pub-type">
        <!-- adds a value mapped for @pub-type, enclosed in parenthesis,
         to a string -->
        <xsl:for-each select="@pub-type">
            <xsl:text> (</xsl:text>
            <span class="data">
                <xsl:choose>
                    <xsl:when test=".='epub'">electronic</xsl:when>
                    <xsl:when test=".='ppub'">print</xsl:when>
                    <xsl:when test=".='epub-ppub'">print and electronic</xsl:when>
                    <xsl:when test=".='epreprint'">electronic preprint</xsl:when>
                    <xsl:when test=".='ppreprint'">print preprint</xsl:when>
                    <xsl:when test=".='ecorrected'">corrected, electronic</xsl:when>
                    <xsl:when test=".='pcorrected'">corrected, print</xsl:when>
                    <xsl:when test=".='eretracted'">retracted, electronic</xsl:when>
                    <xsl:when test=".='pretracted'">retracted, print</xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="."/>
                    </xsl:otherwise>
                </xsl:choose>
            </span>
            <xsl:text>)</xsl:text>
        </xsl:for-each>
    </xsl:template>
    
    <!-- ============================================================= -->
    <!--  "format-date"                                                -->
    <!-- ============================================================= -->
    <!-- Maps a structured date element to a string -->
    
    <xsl:template name="format-date">
        <!-- formats date in DD Month YYYY format -->
        <!-- context must be 'date', with content model:
         (((day?, month?) | season)?, year) -->
        <xsl:for-each select="day|month|season">
            <xsl:apply-templates select="." mode="map"/>
            <xsl:text> </xsl:text>
        </xsl:for-each>
        <xsl:apply-templates select="year" mode="map"/>
    </xsl:template>
    
    
    <xsl:template match="day | season | year" mode="map">
        <xsl:apply-templates/>
    </xsl:template>
    
    
    <xsl:template match="month" mode="map">
        <!-- maps numeric values to English months -->
        <xsl:choose>
            <xsl:when test="number() = 1">January</xsl:when>
            <xsl:when test="number() = 2">February</xsl:when>
            <xsl:when test="number() = 3">March</xsl:when>
            <xsl:when test="number() = 4">April</xsl:when>
            <xsl:when test="number() = 5">May</xsl:when>
            <xsl:when test="number() = 6">June</xsl:when>
            <xsl:when test="number() = 7">July</xsl:when>
            <xsl:when test="number() = 8">August</xsl:when>
            <xsl:when test="number() = 9">September</xsl:when>
            <xsl:when test="number() = 10">October</xsl:when>
            <xsl:when test="number() = 11">November</xsl:when>
            <xsl:when test="number() = 12">December</xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    

    <!-- ========
         | Authors 
    -->
    <xsl:template match="contrib-group[contrib[@contrib-type='author']]">
        <xsl:variable name="id">
            <xsl:call-template name="produce_id"/>
        </xsl:variable>
        <div id="{$id}">
            <ol id="auth-{$id}" class="contributors">
                <xsl:apply-templates select='contrib'/>
            </ol>
            <ol id="aff-{$id}" class="affiliations">
                <xsl:apply-templates select='aff'/>
            </ol>
            <!-- Add the document fragment as the `nas:Byline` -->
            <xsl:value-of select="f:add_relation(concat('doc:',$id),'rdf:type','nas:Byline')"/>
            <xsl:value-of select="f:add_relation(f:get_document_iri(),'schema:hasPart',concat('doc:',$id))"/>
        </div>

    </xsl:template>

    <xsl:template match="contrib[@contrib-type='author']">
        <xsl:param name="refid" select="xref/@rid"/>
        <xsl:call-template name="build_author">
            <xsl:with-param name="authornameid" select="concat($refid, '_author_',count(preceding-sibling::contrib[@contrib-type='author'])+1)" />
            <xsl:with-param name="contributorrole" select="string(role[@vocab='CRediT']/@vocab-term-identifier)"/>
        </xsl:call-template>
    </xsl:template>
    
    
    <xsl:template match="contrib[@contrib-type='author']">
        <xsl:variable name="id">
            <xsl:call-template name="produce_id"/>
        </xsl:variable>
        
        <!-- An author is a person who is an entity mentioned in the article who has the role of author in the context of the creation of the article -->
        <xsl:variable name="person_iri" select="concat('doc:person_',f:hash($id))"/>
        <xsl:variable name="role_iri"   select="concat('doc:role_',  f:hash($id))"/>
        
        <!-- An affiliation is an organization that is an entity mentioned in the article to which the author is affiliated in the context of the creation of the article -->
        <xsl:variable name="affiliation_id"  select="xref/@rid"/>
        <xsl:variable name="organization_iri"  select="concat('doc:organization_',f:hash($affiliation_id))"/>
        
        <!-- The document fragment containing the Author Name -->
        <xsl:value-of select="f:add_relation(f:get_document_iri(),'schema:hasPart',concat('doc:',$id))"/>
        <xsl:value-of select="f:add_relation(concat('doc:',$id),'rdf:type','nas:AuthorName')"/>
        <xsl:value-of select="f:add_relation(concat('doc:',$id),'schema:mentions',$person_iri)"/>
        
        <!-- The Person that has the Role -->       
        <xsl:value-of select="f:add_relation($person_iri,'rdf:type','schema:Person')"/>        
        <xsl:value-of select="f:add_attribute($person_iri,'schema:givenName',string(name/given-names/text()))"/>
        <xsl:value-of select="f:add_attribute($person_iri,'schema:familyName',string(name/surname/text()))"/>
        
        <li id="{$id}" class="{@contribu-type}">
            <xsl:apply-templates>
                <xsl:with-param name="author_id" select="$id"/>
                <xsl:with-param name="person_iri" select="$person_iri"/>
            </xsl:apply-templates>
        </li>
        

        <!-- HTML also supports:
            <link rel="author" href="#xxx"  
        -->
    </xsl:template>
    
    <xsl:template match="contrib[@contrib-type='author']/name/given-names">
        <xsl:param name="author_id" />
        <xsl:param name="person_iri" />
        <span>
            <xsl:value-of select="f:add_attribute($person_iri, 'schema:givenName', string(.))"/>
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    
    <xsl:template match="contrib[@contrib-type='author']/name/surname">
        <xsl:param name="author_id" />
        <xsl:param name="person_iri" />
        <span>
            <xsl:value-of select="f:add_attribute($person_iri, 'schema:familyName', string(.))"/>
            <xsl:apply-templates/>
        </span>
    </xsl:template> 


    <xsl:template name="build_author">
        <xsl:param name="authornameid"/>
        <xsl:param name="contributorrole"/>
        
        <!-- An author is a person who is an entity mentioned in the article who has the role of author in the context of the creation of the article -->
        <xsl:variable name="person_iri" select="concat('doc:person_',f:hash($authornameid))"/>
        <xsl:variable name="role_iri" select="concat('doc:role_',f:hash($authornameid))"/>
        
        <!-- The document fragment containing the Author Name -->
        <xsl:value-of select="f:add_relation(f:get_document_iri(),'schema:hasPart',concat('doc:',$authornameid))"/>
        <xsl:value-of select="f:add_relation(concat('doc:',$authornameid),'rdf:type','nas:AuthorName')"/>
        <xsl:value-of select="f:add_relation(concat('doc:',$authornameid),'schema:mentions',$person_iri)"/>
        
        <!-- The Person that has the Role -->       
        <xsl:value-of select="f:add_relation($person_iri,'rdf:type','schema:Person')"/>        
        <xsl:value-of select="f:add_attribute($person_iri,'schema:givenName',string(name/given-names/text()))"/>
        <xsl:value-of select="f:add_attribute($person_iri,'schema:familyName',string(name/surname/text()))"/>
        
        <xsl:if test="role">
            <xsl:value-of select="f:add_attribute(concat('doc:',$personid),'schema:jobTitle',string(role/text()))"/>
        </xsl:if>
        
        <!-- The Role of the contributor -->
        <xsl:value-of select="f:add_relation(f:get_document_iri(),'schema:contributor',$role_iri)"/>
        <xsl:value-of select="f:add_relation($role_iri,'rdf:type','schema:Role')"/>
        <xsl:value-of select="f:add_relation($role_iri,'schema:roleName',$contributorrole)"/>
        <xsl:value-of select="f:add_relation($role_iri,'schema:contributor',$person_iri)"/>
        
        
        <li id="{$authornameid}" class="{name()}">
            <xsl:apply-templates>
                <xsl:with-param name="authornameid" select="$authornameid"/>
                <xsl:with-param name="personid" select="$personid"/>
            </xsl:apply-templates>
        </li>
    </xsl:template> 

    
    
    <xsl:template match="contrib/contrib-id[@contrib-id-type='orcid']">
        <xsl:param name="personid"/>
        
        <xsl:value-of select="f:add_relation(concat('doc:',$personid),'owl:sameAs',string(text()))"/>
    </xsl:template>

    
    <!-- ==============
         | Affilliation
    -->
    <xsl:template match="aff">
        <xsl:variable name="id">
            <xsl:call-template name="produce_id"/>
        </xsl:variable>
        <li id="{$id}" class="{name()}">
            <xsl:apply-templates/>
        </li>
        
        <xsl:variable name="aff-nodeid" select="$id"/>
        <xsl:variable name="affid" select="concat('organization_',$id)"/>
        <xsl:variable name="organization_iri" select="concat('doc:organization_',f:hash(string($id)))"/>
        
        <xsl:value-of select="f:add_relation(concat('doc:',$id),'rdf:type','nas:AffiliationItem')"/>
        <xsl:value-of select="f:add_relation(f:get_document_iri(),'schema:hasPart',concat('doc:',$id))"/>
        
        <!-- The document fragment mentions the organization, that has a property name -->
        <xsl:value-of select="f:add_relation(concat('doc:',$id),'schema:mentions',$organization_iri)"/>
        <xsl:value-of select="f:add_relation($organization_iri,'rdf:type','schema:Organization')"/>
        <xsl:value-of select="f:add_attribute($organization_iri,'schema:name',string(text()))"/>
        
        <xsl:for-each select="//contrib[@contrib-type='author' and xref[@ref-type='aff' and @rid=$aff-nodeid]]">
            <xsl:variable name="authornameid">
                <xsl:call-template name="produce_id"/>
            </xsl:variable>
            <xsl:variable name="person_iri" select="concat('doc:person_',f:hash($authornameid))"/>
            <xsl:value-of select="f:add_relation($person_iri,'schema:affiliation',$organization_iri)"/>
        </xsl:for-each>
        
    </xsl:template>
    
    <xsl:template match="institution-wrap">
        <xsl:variable name="id">
            <xsl:call-template name="produce_id"/>
        </xsl:variable>
        <span id="{$id}">
            <xsl:apply-templates select='institution'/>
            <xsl:choose>
                <xsl:when test="institution-id">
                    <xsl:for-each select="institution-id">
                        <xsl:choose>
                            <xsl:when test="@institution-id-type='Ringgold'">  
                                <a href="{concat('https://ido.ringgold.com/institution/', translate(.,' ',''))}">
                                    <xsl:text> (</xsl:text>
                                    <xsl:value-of select="@institution-id-type"/>
                                    <xsl:text>:</xsl:text>
                                        <xsl:value-of select="."/>
                                    <xsl:text>)</xsl:text>
                                </a>
                            </xsl:when>
                            <xsl:when test="@institution-id-type='ISNI'">  
                                <a href="{concat('https://isni.org/isni/', translate(.,' ',''))}">
                                    <xsl:text> (</xsl:text>
                                    <xsl:value-of select="@institution-id-type"/>
                                    <xsl:text>:</xsl:text>
                                    <xsl:value-of select="."/>
                                    <xsl:text>)</xsl:text>
                                </a>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text> (</xsl:text>
                                <xsl:value-of select="@institution-id-type"/>
                                <xsl:text>:</xsl:text>
                                <xsl:value-of select="."/>
                                <xsl:text>)</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </span>
    </xsl:template>
    
    <xsl:template match="institution">
         <xsl:apply-templates/>
    </xsl:template>






    <!-- =======
        Keywords
        https://jats.nlm.nih.gov/archiving/tag-library/1.4/element/kwd-group.html    
    -->
    
    <xsl:template match="kwd-group">
        <xsl:variable name="id">
            <xsl:call-template name="produce_id"/>
        </xsl:variable>
        <!-- Type the section as a `nas:Keyword -->
        <xsl:value-of select="f:add_relation(concat('doc:',$id),'rdf:type','nas:Keywords')"/>
        <xsl:value-of select="f:add_relation(f:get_document_iri(),'schema:hasPart',concat('doc:',$id))"/>
        <section id="{$id}" class="{name()}">
            <xsl:apply-templates select="title"/>  
            <ol id="list-{$id}">
                <xsl:apply-templates select="kwd"/>    
            </ol>
        </section>
    </xsl:template>

    <xsl:template match="kwd">
        <xsl:variable name="id">
            <xsl:call-template name="produce_id"/>
        </xsl:variable>
        <xsl:value-of select="f:add_relation(concat('doc:',$id),'rdf:type','nas:Term')"/>
        <xsl:value-of select="f:add_relation(f:get_document_iri(),'schema:hasPart',concat('doc:',$id))"/>
        <li id="{$id}" class="{name()}">
            <xsl:apply-templates/>
        </li>
    </xsl:template>

    <!-- ============= 
        Abstract
        https://jats.nlm.nih.gov/archiving/tag-library/1.4/element/abstract.html
    -->
    <xsl:template match="abstract">
        <xsl:variable name="id">
            <xsl:call-template name="produce_id"/>
        </xsl:variable>
        <xsl:value-of select="f:add_relation(concat('doc:',$id),'rdf:type','nas:Abstract')"/>
        <xsl:value-of select="f:add_relation(f:get_document_iri(),'schema:hasPart',concat('doc:',$id))"/>
        <section id="{$id}" class="{name()}">
            <xsl:apply-templates/>
        </section>
    </xsl:template>

    <!-- ============= 
        Acknowledgment
        https://jats.nlm.nih.gov/archiving/tag-library/1.4/element/ack.html
    -->
    <xsl:template match="ack">
        <xsl:variable name="id">
            <xsl:call-template name="produce_id"/>
        </xsl:variable>
        <xsl:value-of select="f:add_relation(concat('doc:',$id),'rdf:type','nas:Acknowledgement')"/>
        <xsl:value-of select="f:add_relation(f:get_document_iri(),'schema:hasPart',concat('doc:',$id))"/>
        <section id="{$id}">
            <xsl:apply-templates/>
        </section>
    </xsl:template>

 

    <!--  ============================
          |  Bibliography and References
          https://jats.nlm.nih.gov/archiving/tag-library/1.4/chapter/tag-refs.html#arc-tag-refs
          
          <p>...<xref id="e123" ref-type="bibr" rid="e987">B1</xref>....</p>
          <ref-list>
            <ref id="e987"><label>B1</label><mixed-citation>..</mixed-citation></ref>
          </ref-list>
    -->
    <xsl:template match="ref-list">
        <xsl:variable name="id">
            <xsl:call-template name="produce_id"/>
        </xsl:variable>
        <section id="{$id}">
            <xsl:apply-templates select="title"/>
            <ol id="list-{$id}">
                <xsl:apply-templates select="ref"/>
            </ol>
        </section>
        <xsl:value-of select="f:add_relation(concat('doc:',$id),'rdf:type','nas:References')"/>
        <xsl:value-of select="f:add_relation(f:get_document_iri(),'schema:hasPart',concat('doc:',$id))"/>
    </xsl:template>


    <xsl:template match="ref">
        <xsl:variable name="id">
            <xsl:call-template name="produce_id"/>
        </xsl:variable>
        <xsl:variable name="work_iri" select="concat('doc:work_',f:hash(string($id)))"/>
        <li id="{$id}" value="{string(label)}">
            <!-- if for some ref, there is a linked xref, then link back to there, using the label, if there is one -->
            <xsl:choose>
                <xsl:when test="//xref[@rid=$id]/@id">
                    <xsl:choose>
                        <xsl:when test="label">
                            <xsl:apply-templates>
                                <xsl:with-param name="linkback" select="//xref[@rid=$id]/@id"/>
                            </xsl:apply-templates>                    
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- if there is no label, create a link on a pointing arrow -->
                            <a href="{concat('#',//xref[@rid=$id]/@id)}">&#x21A5;</a>
                            <xsl:apply-templates/>
                        </xsl:otherwise>
                    </xsl:choose>
                    <!-- the document fragment in the ref-list representing a biblographic reference is a `nas:ReferenceItem` -->
                    <xsl:value-of select="f:add_relation(f:get_document_iri(), 'schema:hasPart', concat('doc:',$id))"/>
                    <xsl:value-of select="f:add_relation(concat('doc:',string($id)),'rdf:type','nas:ReferenceItem')"/>
                    <xsl:value-of select="f:add_relation(concat('doc:',string($id)),'schema:mentions',$work_iri)"/>
                    
                    <!-- the document fragment in the body pointing to a biblographic reference is a `nas:Citation` -->
                    <xsl:for-each select="//xref[@rid=$id]">
                        <xsl:value-of select="f:add_relation(concat('doc:',string(/@id)),'rdf:type','nas:Citation')"/>
                        <xsl:value-of select="f:add_relation(concat('doc:',string(@id)),'schema:mentions',$work_iri)"/>    
                    </xsl:for-each>

                </xsl:when>
                <xsl:otherwise>
                        <xsl:apply-templates>
                            
                        </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </li>
        
        <xsl:variable name="work_id" select="concat('work','_',f:hash(string($id)))"/>
        
   
    
       
        <!--
        <xsl:value-of select="f:add_relation(f:get_document_iri(), 'schema:citation', concat('doc:',$refid))"/>
        -->    
        <xsl:value-of select="f:add_relation(concat('doc:',$id), 'schema:mentions', concat('doc:',$work_id))"/> 
        <xsl:value-of select="f:add_relation(concat('doc:',$work_id), 'rdf:type', 'schema:CreativeWork')"/> 
        <xsl:value-of select="f:add_attribute(concat('doc:',$work_id), 'schema:label', 'test')"/> 
        
        <xsl:value-of select="f:add_relation(f:get_document_iri(), 'schema:hasPart', concat('doc:',$id))"/>
        <xsl:value-of select="f:add_relation(concat('doc:',$id),'rdf:type','nas:ReferenceItem')"/>
    </xsl:template>


    <!-- ======
        Figures 
    -->
    <xsl:template match="fig">
        <xsl:variable name="id">
            <xsl:call-template name="produce_id"/>
        </xsl:variable>
        <xsl:variable name="altText" select="string(alt-text/.)"/>
    
        <figure id="{$id}">
            <img src="{string(./graphic/@xlink:href)}" alt="{$altText}"/>
            <xsl:apply-templates select="caption" mode="figure"/>
        </figure>
    </xsl:template>
    
    <xsl:template match="caption" mode="figure">
        <xsl:variable name="id"><xsl:call-template name="produce_id"/></xsl:variable>
        <figcaption id="{$id}">
            <xsl:apply-templates select="preceding-sibling::label"/>
            <xsl:apply-templates/>
        </figcaption>
    </xsl:template>


    <!-- =====
        | Tables 
        | Copied from jatskit-html.xsl and adapted
    -->
    

    
    <xsl:template match="table-wrap">
        <xsl:apply-templates select="table"/>
        <xsl:apply-templates select="table-wrap-foot"/>
    </xsl:template> 
    
    <xsl:template match="table | thead | tbody | tfoot | col | colgroup | tr | th | td">
        <xsl:variable name="id">
            <xsl:call-template name="produce_id"/>
        </xsl:variable>
        <xsl:copy>
            <xsl:attribute name="id">
                <xsl:value-of select="$id"/>
            </xsl:attribute>
            <xsl:apply-templates select="@*" mode="table-copy"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    
    
    <xsl:template match="array/tbody">
        <table>
            <xsl:copy>
                <xsl:apply-templates select="@*" mode="table-copy"/>
                <xsl:apply-templates/>
            </xsl:copy>
        </table>
    </xsl:template>
    
    
    <xsl:template match="@*" mode="table-copy">
        <xsl:copy-of select="."/>
    </xsl:template>
    
    
    <xsl:template match="@content-type" mode="table-copy"/>
       
    <xsl:template match="table-wrap-foot/fn-group">
        <div>
            <xsl:apply-templates select="fn"/>
        </div>
    </xsl:template>

<!--    <xsl:template match="table">
        <xsl:variable name="id">
            <xsl:call-template name="produce_id"/>
        </xsl:variable>
        <table id="{$id}">
            <xsl:apply-templates select="caption" mode="table"/>
            <xsl:copy-of select="thead"/>
            <xsl:apply-templates select="tbody"/>
            <xsl:apply-templates select="tfoot"/>
        </table>
    </xsl:template>

    <xsl:template match="caption" mode="table">
        <xsl:variable name="id">
            <xsl:call-template name="produce_id"/>
        </xsl:variable>
        <caption id="{$id}">
            <xsl:apply-templates select="preceding-sibling::label"/>
            <xsl:apply-templates/>
        </caption>
    </xsl:template>-->
    
    <xsl:template name="named-anchor">
        <!-- Copied from jatskit-html.xsl
            generates an HTML named anchor -->
        <xsl:variable name="id">
            <xsl:choose>
                <xsl:when test="@id">
                    <!-- if we have an @id, we use it -->
                    <xsl:value-of select="@id"/>
                </xsl:when>
                <xsl:when test="not(preceding-sibling::*) and
                    (parent::alternatives | parent::name-alternatives |
                    parent::citation-alternatives | parent::collab-alternatives |
                    parent::aff-alternatives)/@id">
                    <!-- if not, and we are first among our siblings inside one of
               several 'alternatives' wrappers, we use its @id if available -->
                    <xsl:value-of select="(parent::alternatives | parent::name-alternatives |
                        parent::citation-alternatives | parent::collab-alternatives |
                        parent::aff-alternatives)/@id"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- otherwise we simply generate an ID -->
                    <xsl:value-of select="generate-id(.)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <a id="{$id}">
            <xsl:comment> named anchor </xsl:comment>
        </a>
    </xsl:template>
    

    <!-- ==================
         | Other xrefs
    -->
     <xsl:template match="xref">
        <xsl:variable name="id">
            <xsl:call-template name="produce_id"/>
        </xsl:variable>
        <a id="{$id}" href="#{@rid}">
            <xsl:apply-templates/>
        </a>
        <xsl:if test="@ref-type='bibr'">
            <!-- an xref of type 'bibr' is a citation to a ref in a ref-list -->
            <xsl:value-of select="f:add_relation(f:get_document_iri(),'schema:hasPart',concat('doc:',$id))"/>
            <xsl:value-of select="f:add_relation(concat('doc:',$id),'rdf:type','nas:Citation')"/>
        </xsl:if>
    </xsl:template>
    
    <!-- ==================
         | ext-link
    -->
    <xsl:template match="ext-link">
        <xsl:variable name="id">
            <xsl:call-template name="produce_id"/>
        </xsl:variable>
        <a id="{$id}" class="{@ext-link-type}" href="{@xlink:href}">
            <xsl:apply-templates/>
        </a>
    </xsl:template>



    <!-- ========= 
         | Formatting 
    -->
    <xsl:template match="sup|sub">
        <xsl:variable name="id">
            <xsl:call-template name="produce_id"/>
        </xsl:variable>
        <xsl:element name="{name()}">
            <xsl:attribute name="id">
                <xsl:value-of select="$id"/>
            </xsl:attribute>
        </xsl:element>
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="monospace">
        <xsl:variable name="id">
            <xsl:call-template name="produce_id"/>
        </xsl:variable>
        <span id="{$id}" style="font-family: monospace;">
            <xsl:apply-templates/>
        </span>
     </xsl:template>

    <xsl:template match="italic|bold">
        <xsl:variable name="id">
            <xsl:call-template name="produce_id"/>
        </xsl:variable>
        <span id="{$id}" style="{concat('font-style: ',name(),';')}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>


    <!-- ==================
        MathML / Formulas
     -->
    <xsl:template match="inline-formula">
        <xsl:variable name="id">
            <xsl:call-template name="produce_id"/>
        </xsl:variable>
        <span id="{$id}" class="{name()}">
            <xsl:apply-templates/>
        </span>
        <xsl:value-of select="f:add_relation(concat('doc:',$id),'rdf:type','nas:Formula')"/>
    </xsl:template>

    <xsl:template match="disp-formula">
        <xsl:variable name="id">
            <xsl:call-template name="produce_id"/>
        </xsl:variable>
        <div id="{$id}" class="{name()}">
            <xsl:apply-templates/>
        </div>
        <xsl:value-of select="f:add_relation(concat('doc:',$id),'rdf:type','nas:Formula')"/>
    </xsl:template>

    <xsl:template match="mml:math">
        <xsl:variable name="id">
            <xsl:call-template name="produce_id"/>
        </xsl:variable>
        <math id="{$id}" class="{name()}">
            <xsl:apply-templates mode="removenamespace"/>
        </math>
    </xsl:template>

    <!-- strip namespaces
        =================
        from all MathML elements and attributes 
    -->
    <xsl:template match="*" mode="removenamespace">
        <!-- remove element prefix -->
        <xsl:element name="{local-name()}">
          <!-- process attributes -->
          <xsl:for-each select="@*">
            <!-- remove attribute prefix -->
            <xsl:attribute name="{local-name()}">
              <xsl:value-of select="."/>
            </xsl:attribute>
          </xsl:for-each>
          <xsl:apply-templates mode="removenamespace"/>
        </xsl:element>
    </xsl:template>


    <!-- ======
         | Generic 
    -->
    <xsl:template match="body">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="label">
        <xsl:param name = "linkback" /><!-- for references -->
        <xsl:variable name="id">
            <xsl:call-template name="produce_id"/>
        </xsl:variable>
        <span id="{$id}" class="{name()}">
            <xsl:choose>
                <xsl:when test="$linkback">
                    <a href="{concat('#',$linkback)}">
                        <xsl:apply-templates/>
                    </a>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </span>
    </xsl:template>
    
    <xsl:template match="uri">
        <xsl:variable name="id">
            <xsl:call-template name="produce_id"/>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="@xlink:href">
                <a id="{$id}" href="{@xlink:href}">
                    <xsl:apply-templates/>
                </a>
            </xsl:when>
            <xsl:otherwise>
                <a id="{$id}" href="{text()}">
                    <xsl:apply-templates/>
                </a>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>

    <!-- ======
         | Section 
    -->
    <xsl:template match="sec">
        <xsl:variable name="id">
            <xsl:call-template name="produce_id"/>
        </xsl:variable>
        <xsl:variable name="sectionType" select="@sec-type"/>
        <xsl:choose>
            <xsl:when test="@sec-type">
                <section id="{$id}" class="{concat(name(),'-',$sectionType)}">
                    <xsl:if test="$sectionType='nomenclature'">
                        <xsl:value-of select="f:add_relation(f:get_document_iri(), 'schema:hasPart', concat('doc:',$id))"/>
                        <xsl:value-of select="f:add_relation(concat('doc:',$id),'rdf:type','nas:Nomenclature')"/>
                            
                    </xsl:if>
                    <xsl:apply-templates/>
                </section>
            </xsl:when>
            <xsl:otherwise>
                <section id="{$id}" class="{name()}">
                    <xsl:apply-templates/>
                </section>
            </xsl:otherwise>
        </xsl:choose>
        

        <xsl:choose>
            <xsl:when test="$sectionType='conclusions'">
                <xsl:value-of select="f:add_relation(concat('doc:',$id),'rdf:type','nas:Conclusion')"/>
                <xsl:value-of select="f:add_relation(f:get_document_iri(),'schema:hasPart',concat('doc:',$id))"/>
            </xsl:when>
            <xsl:when test="$sectionType='intro'">
                <xsl:value-of select="f:add_relation(concat('doc:',$id),'rdf:type','nas:Introduction')"/>
                <xsl:value-of select="f:add_relation(f:get_document_iri(),'schema:hasPart',concat('doc:',$id))"/>
            </xsl:when>
            <xsl:when test="$sectionType='materials'">
                <xsl:value-of select="f:add_relation(concat('doc:',$id),'rdf:type','nas:Materials')"/>
                <xsl:value-of select="f:add_relation(f:get_document_iri(),'schema:hasPart',concat('doc:',$id))"/>
            </xsl:when>
            <xsl:when test="$sectionType='methods'">
                <xsl:value-of select="f:add_relation(concat('doc:',$id),'rdf:type','nas:Methods')"/>
                <xsl:value-of select="f:add_relation(f:get_document_iri(),'schema:hasPart',concat('doc:',$id))"/>
            </xsl:when> 
            <xsl:otherwise>
                <!-- ignore -->
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <!-- ===============
         | Section title
    -->
    <xsl:template match="sec/title| ref-list/title| kwd-group/title| def-list/title| fn-group/title| glossary/title| list/title| abstract/title">
        <xsl:variable name="id">
            <xsl:call-template name="produce_id"/>
        </xsl:variable>
        <xsl:element name="h{count(ancestor::sec| ancestor::ref-list| ancestor::kwd-group| ancestor::def-list| ancestor::fn-group| ancestor::glossary| ancestor::list| ancestor::abstract)+1}">
            <xsl:attribute name="id">
                <xsl:value-of select="$id"/>
            </xsl:attribute>
            <xsl:attribute name="class">
                <xsl:value-of select="name()"/>
            </xsl:attribute>
            <xsl:if test="ancestor::sec[1]/label">
                <span class="label">
                    <xsl:value-of select="ancestor::sec[1]/label"/>
                </span>
            </xsl:if>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <!-- ===============
         | Footnote
    -->    
    <xsl:template match="fn">
        <xsl:variable name="id">
            <xsl:call-template name="produce_id"/>
        </xsl:variable>
        <aside id="{$id}" class="{name()}">
            <xsl:apply-templates/>
        </aside>
    </xsl:template>
    
    <!-- ===============
         | Code
    -->
    <xsl:template match="code">
        <xsl:variable name="id">
            <xsl:call-template name="produce_id"/>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="@code-type or @language">
               <pre>
                   <code id="{$id}" class="{@code-type}{@language}">
                       <xsl:apply-templates/>
                   </code>
               </pre> 
            </xsl:when>
            <xsl:otherwise>
                <code id="{$id}" class="{@language}">
                    <xsl:apply-templates/>
                </code>                    
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- ===============
         | List
    --> 
    <xsl:template match="list">
        <xsl:variable name="id">
            <xsl:call-template name="produce_id"/>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="@list-type='order' or @list-type='alpha-lower' or @list-type='alpha-upper' or @list-type='roman-lower' or @list-type='roman-upper'">
                <ul id="{$id}" class="{@list-type}">
                    <xsl:apply-templates/>
                </ul>                
            </xsl:when>
            <xsl:when test="@list-type='bullet' or @list-type='simple' or @list-type='unorder'">
                <ul id="{$id}" class="{@list-type}">
                    <xsl:apply-templates/>
                </ul>
            </xsl:when>
            <xsl:otherwise>
                <ul id="{$id}" class="{name()}">
                    <xsl:apply-templates/>
                </ul>                
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="list-item">
        <xsl:variable name="id"><xsl:call-template name="produce_id"/></xsl:variable>
        <li id="{$id}" class="{name()}">
            <xsl:apply-templates/>
        </li>
    </xsl:template>
    
    <xsl:template match="p[list]|p[p]">
        <xsl:variable name="id"><xsl:call-template name="produce_id"/></xsl:variable>
        <div id="{$id}">
            <xsl:apply-templates />
        </div>
    </xsl:template>
    
    <xsl:template match="p">
        <xsl:variable name="id"><xsl:call-template name="produce_id"/></xsl:variable>
        <p id="{$id}">
            <xsl:apply-templates />
        </p>
    </xsl:template>
    
    <!-- ===============
         | Definition List
    --> 
    <xsl:template match="def-list">
        <xsl:variable name="id">
            <xsl:call-template name="produce_id"/>
        </xsl:variable>
        <xsl:apply-templates select="title"/>
        <dl id="{$id}">
            <xsl:apply-templates select="def-item"/>
        </dl>
    </xsl:template>
    
    <!-- ===============
         | Definition List item
    --> 
    <xsl:template match="def-item">
        <xsl:variable name="id"><xsl:call-template name="produce_id"/></xsl:variable>
        <div id="{$id}">
            <xsl:apply-templates select="term"/>
            <xsl:apply-templates select="def"/>
        </div>
    </xsl:template>
    
    <xsl:template match="term">
        <xsl:variable name="id"><xsl:call-template name="produce_id"/></xsl:variable>
        <dt id="{$id}">
            <xsl:apply-templates/>
        </dt>
    </xsl:template>
    
    <xsl:template match="def">
        <xsl:variable name="id"><xsl:call-template name="produce_id"/></xsl:variable>
        <dd id="{$id}">
            <xsl:apply-templates/>
        </dd>
    </xsl:template>
    
    
 <!-- Leave empty -->
    <xsl:template match="nothing|content-language|named-content">
    </xsl:template>

</xsl:stylesheet>