<?xml version="1.0" encoding="UTF-8" ?>

<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:t="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="t"
    version="1.0">

  <xsl:param name="id" select="''"/>
  <xsl:param name="doc" select="''"/>
  <xsl:param name="hostname" select="''"/>

  <xsl:output method="xml"
	      encoding="UTF-8"
	      indent="yes"/>

  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="t:TEI">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="t:teiHeader"/>

  <xsl:template match="t:group">
    <xsl:apply-templates select="t:text"/>
  </xsl:template>

  <xsl:template match="t:text">
    <div>
      <xsl:call-template name="add_id"/>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="t:front">
    <div>
      <xsl:call-template name="add_id"/>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="t:titlePage">
    <div class="title-page">
      <xsl:apply-templates/>   
    </div>
  </xsl:template>

  <xsl:template match="t:publisher">
    <span class="title-page-doc-publisher">
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <xsl:template match="t:titlePage/t:docAuthor">
    <h2 class="title-page-doc-author">
      <xsl:apply-templates/>
    </h2>
  </xsl:template>

  <xsl:template match="t:titlePage/t:docTitle">
    <h1 class="title-page-doc-title">
      <xsl:apply-templates/>
    </h1>
  </xsl:template>

  <xsl:template match="t:titlePage/t:docImprint">
    <h3 class="title-page-doc-imprint">
      <xsl:apply-templates/>
    </h3>
  </xsl:template>

  <xsl:template match="t:body">
    <div>
      <xsl:call-template name="add_id"/>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="t:back">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="t:div|t:div1|t:div2|t:div3">
    <div>
      <xsl:call-template name="add_id"/>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="t:listBibl">
  </xsl:template>

  <xsl:template match="t:bibl">
  </xsl:template>

  <xsl:template match="t:note">
  </xsl:template>

  <xsl:template match="t:quote">
    <q><xsl:apply-templates/></q>
  </xsl:template>

  <xsl:template match="t:head">
    <h2>
      <xsl:call-template name="add_id"/>
      <xsl:apply-templates/>
    </h2>
  </xsl:template>

  <xsl:template match="t:p">
    <p>
      <xsl:call-template name="add_id"/>
      <xsl:apply-templates/>
    </p>
  </xsl:template>

 <xsl:template match="t:lb">
   <xsl:element name="br">
     <xsl:call-template name="add_id"/>
   </xsl:element>
 </xsl:template>

  <xsl:template match="t:lg">
    <p>
      <xsl:call-template name="add_id"/>
      <xsl:apply-templates/>
    </p>
  </xsl:template>

  <xsl:template match="t:l">
    <xsl:apply-templates/>
    <xsl:element name="br"><xsl:call-template name="add_id_empty_elem"/></xsl:element>
  </xsl:template>

  <xsl:template match="t:ref">
    <xsl:element name="a">
      <xsl:call-template name="add_id"/>
      <xsl:if test="@target">
	<xsl:attribute name="href">
	  <xsl:apply-templates select="@target"/>
	</xsl:attribute>
      </xsl:if>
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="t:list[@type='ordered']">
    <ol><xsl:call-template name="add_id"/><xsl:apply-templates/></ol>
  </xsl:template>

  <xsl:template match="t:list">
    <ul><xsl:call-template name="add_id"/><xsl:apply-templates/></ul>
  </xsl:template>

  <xsl:template match="t:hi[@rend='bold']|t:emph[@rend='bold']">
    <strong> <xsl:call-template name="add_id"/><xsl:apply-templates/></strong>
  </xsl:template>

  <xsl:template match="t:hi[@rend='italics']|t:emph[@rend='italics']">
    <em><xsl:call-template name="add_id"/><xsl:apply-templates/></em>
  </xsl:template>

  <xsl:template match="t:hi[@rend='spat']">
    <em><xsl:call-template name="add_id"/><xsl:apply-templates/></em>
  </xsl:template>

  <xsl:template match="t:item">
    <li><xsl:call-template name="add_id"/><xsl:apply-templates/></li>
  </xsl:template>

  <xsl:template match="t:figure">
    <xsl:element name="div">
      <xsl:call-template name="add_id"/>
      <xsl:attribute name="id"><xsl:value-of select="@xml:id"/></xsl:attribute>
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="t:figure/t:head">
    <p>
      <xsl:call-template name="add_id"/>
      <small>
	<xsl:apply-templates/>
      </small>
    </p>
  </xsl:template>

  <xsl:template match="t:graphic">
    <xsl:element name="img">
      <xsl:attribute name="src">
	<xsl:apply-templates select="@url"/>
      </xsl:attribute>
      <xsl:call-template name="add_id"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="t:address">
    <xsl:element name="br"/>
    <xsl:call-template name="add_id_empty_elem"/>
    <xsl:for-each select="t:addrLine">
      <xsl:apply-templates/><xsl:element name="br"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="t:sp">
    <dl>
      <xsl:call-template name="add_id"/>
      <dt>
	<xsl:apply-templates select="t:speaker"/>
      </dt>
      <dd>
	<xsl:apply-templates select="t:stage|t:p|t:lg|t:pb"/>
      </dd>
    </dl>
  </xsl:template>

  <xsl:template match="t:speaker">
    <xsl:element name="span">
      <xsl:call-template name="add_id"/>
      <xsl:apply-templates/>
    </xsl:element>
    <xsl:text>
    </xsl:text>
  </xsl:template>

  <xsl:template match="t:sp/t:stage|t:p/t:stage|t:lg/t:stage|t:l/t:stage">
    <em><xsl:text>
      (</xsl:text><xsl:element name="span">
      <xsl:call-template name="add_id"/>
      <xsl:apply-templates/>
    </xsl:element><xsl:text>) </xsl:text></em>
  </xsl:template>


  <xsl:template match="t:stage">
    <xsl:element name="p">
      <xsl:call-template name="add_id"/>
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="t:pb">
    <xsl:element name="span">
      <xsl:call-template name="add_id_empty_elem"/>
      <xsl:text>[</xsl:text>
      <xsl:element name="a">
	<xsl:attribute name="data-no-turbolink">true</xsl:attribute>
        <xsl:attribute name="href">        
	  <xsl:choose>
	    <xsl:when test="$id">
	      <xsl:value-of select="concat('/catalog/',
				    substring-before($doc,'.xml'),
				    '%23',
				    $id,
				    '/facsimile#',@xml:id)"/>
	    </xsl:when>
	    <xsl:otherwise>
              <xsl:value-of select="concat('/catalog/',
				    substring-before($doc,'.xml'),
				    '/facsimile#',@xml:id)"/>
	    </xsl:otherwise>
	  </xsl:choose>
	</xsl:attribute>
	<xsl:text>s. </xsl:text>
	<small><xsl:value-of select="@n"/></small>
	</xsl:element><xsl:text>]</xsl:text>
    </xsl:element>
  </xsl:template>

  <xsl:template name="add_id">
    <xsl:call-template name="add_id_empty_elem"/>
    <xsl:if test="not(descendant::node())">
      <xsl:comment>Instead of content</xsl:comment>
    </xsl:if>
  </xsl:template>

  <xsl:template name="add_id_empty_elem">
    <xsl:if test="@xml:id">
      <xsl:attribute name="id">
	<xsl:value-of select="@xml:id"/>
      </xsl:attribute>
    </xsl:if>
  </xsl:template>


</xsl:stylesheet>
