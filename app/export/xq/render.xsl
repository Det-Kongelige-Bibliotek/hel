<?xml version="1.0" encoding="UTF-8" ?>

<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:t="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.w3.org/1999/xhtml" 
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
    <xsl:element name="html">
      <xsl:element name="head">
	<xsl:element name="meta">
	  <xsl:attribute name="http-equiv">Content-Type</xsl:attribute>
	  <xsl:attribute name="content">text/html;charset=UTF-8</xsl:attribute>
	</xsl:element>
	<xsl:element name="title">
	  <xsl:apply-templates 
	      select="t:teiHeader/t:fileDesc/t:sourceDesc/t:bibl/t:title"/>
	</xsl:element>
      </xsl:element>
      <xsl:element name="body">
	<p>
	  <xsl:value-of select="$id"/> |<br/>
	  <xsl:value-of select="$doc"/> |<br/>
	  <xsl:value-of select="$hostname"/>
	</p>
	<xsl:apply-templates/>
      </xsl:element>
    </xsl:element>
  </xsl:template>

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
      <h2>hitting front</h2>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="t:body">
    <div>
      <xsl:call-template name="add_id"/>
      <h2>hitting body</h2>
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

  <xsl:template match="t:lg">
    <p>
      <xsl:call-template name="add_id"/>
      <xsl:apply-templates/>
    </p>
  </xsl:template>

  <xsl:template match="t:l">
    <xsl:apply-templates/>
    <xsl:element name="br"><xsl:call-template name="add_id"/></xsl:element>
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
    <ol><xsl:apply-templates/></ol>
  </xsl:template>

  <xsl:template match="t:list">
    <ul><xsl:apply-templates/></ul>
  </xsl:template>

  <xsl:template match="t:hi[@rend='bold']|t:emph[@rend='bold']">
    <strong><xsl:apply-templates/></strong>
  </xsl:template>

  <xsl:template match="t:hi[@rend='italics']|t:emph[@rend='italics']">
    <em><xsl:apply-templates/></em>
  </xsl:template>

  <xsl:template match="t:hi[@rend='spat']">
    <em><xsl:apply-templates/></em>
  </xsl:template>

  <xsl:template match="t:item">
    <li><xsl:apply-templates/></li>
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
    <xsl:call-template name="add_id"/>
    <xsl:for-each select="t:addrLine">
      <xsl:apply-templates/><xsl:element name="br"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="t:sp">
    <dl>
      <xsl:call-template name="add_id"/>
      <dt>
	<xsl:apply-templates select="t:speaker"/>
	<xsl:apply-templates select="t:stage"/>
      </dt>
      <dd>
	<xsl:apply-templates select="t:p|t:lg|t:pb"/>
      </dd>
    </dl>
  </xsl:template>

  <xsl:template match="t:pb">
    <xsl:element name="span"><xsl:text>[</xsl:text>
      <xsl:call-template name="add_id"/>
      <xsl:text>s. </xsl:text><small><xsl:value-of select="@n"/></small>
      <xsl:text>]</xsl:text></xsl:element>
  </xsl:template>

  <xsl:template name="add_id">
    <xsl:if test="@xml:id">
      <xsl:attribute name="id">
	<xsl:value-of select="@xml:id"/>
      </xsl:attribute>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
