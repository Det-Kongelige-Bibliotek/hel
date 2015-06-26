<?xml version="1.0" encoding="UTF-8" ?>
<!--

Author Sigfrid Lundberg slu@kb.dk

Last updated $Date: 2008/06/24 12:56:46 $ by $Author: slu $

$Id: toc.xsl,v 1.2 2008/06/24 12:56:46 slu Exp $

-->
<xsl:transform version="1.0"
	       xmlns:t="http://www.tei-c.org/ns/1.0"
	       xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	       exclude-result-prefixes="t">

  <xsl:output encoding="UTF-8"
	      indent="yes"
	      method="xml"
	      omit-xml-declaration="yes"/>

  <xsl:template match="/">
    <div>
      <ul>
	<xsl:apply-templates select="./t:div|./t:text"/>
      </ul>
    </div>
  </xsl:template>

  <xsl:template match="t:div">
    <div>
      <ul>
	<xsl:apply-templates select="child::node()[@decls]"/>
      </ul>
    </div>
  </xsl:template>

  <xsl:template match="t:div|t:div0|t:div1|t:div2|t:div3|t:div4|t:div5">
    <xsl:element name="li">
      <xsl:attribute name="id">
	<xsl:value-of select="concat('#','toc',@xml:id)"/>
      </xsl:attribute>

      <xsl:call-template name="add_anchor"/>
      <xsl:if test="t:div|t:div0|t:div1|t:div2|t:div3|t:div4|t:div5">
	<ul>
	  <xsl:apply-templates
	      select="t:div|t:div0|t:div1|t:div2|t:div3|t:div4|t:div5"/>
	</ul>
      </xsl:if>
    </xsl:element>

  </xsl:template>

  <xsl:template match="t:head">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="t:lb">
    <xsl:text> 
    </xsl:text>
  </xsl:template>

  <xsl:template name="add_anchor">
    <xsl:element name="a">
      <xsl:attribute name="href">
	<xsl:value-of select="concat('#',@xml:id)"/>
      </xsl:attribute>
      <xsl:choose>
	<xsl:when test="t:head">
	  <xsl:apply-templates select="t:head"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:variable name="some_text">
	    <xsl:apply-templates select=".//*/text()"/>
	  </xsl:variable>
	  <xsl:value-of
	      select="substring(normalize-space($some_text),1,20)"/>
	  <xsl:text>...</xsl:text>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:element>
  </xsl:template>

  <xsl:template match="t:teiHeader"/>

  <xsl:template match="t:front"/>

  <xsl:template match="t:text">
    <xsl:apply-templates select="t:body"/>
  </xsl:template>

  <xsl:template match="t:body">
    <li>
      <xsl:call-template name="add_anchor"/>
      <xsl:if test="t:div|t:div0|t:div1|t:div2|t:div3|t:div4|t:div5">
	<ul>
	  <xsl:apply-templates
	      select="t:div|t:div0|t:div1|t:div2|t:div3|t:div4|t:div5"/>
	</ul>
      </xsl:if>
    </li>
  </xsl:template>

  <xsl:template match="t:hi">
    <xsl:apply-templates/>
  </xsl:template>

</xsl:transform>

