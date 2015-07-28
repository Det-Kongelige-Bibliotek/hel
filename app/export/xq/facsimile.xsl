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
    <xsl:choose>
      <xsl:when test="$id">
	<div>
	  <xsl:attribute name="id">
	    <xsl:value-of select="$id"/>
	  </xsl:attribute>
	  <xsl:apply-templates select="//node()[@xml:id=$id]/preceding::t:pb[1]"/>
	  <xsl:for-each select="//node()[@xml:id=$id]//t:pb">
	    <xsl:apply-templates select="."/>
	  </xsl:for-each>
	</div>
      </xsl:when>
      <xsl:otherwise>
	<div>
	  <xsl:for-each select="//t:pb">
	    <xsl:apply-templates select="."/>
	  </xsl:for-each>
	</div>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="t:pb">
    <xsl:element name="div">
      <xsl:call-template name="add_id"/>
      <xsl:element name="img">
        <xsl:call-template name="img_ref"/>
      </xsl:element>
      <xsl:text>[</xsl:text>
      <xsl:text>s. </xsl:text><small><xsl:value-of select="@n"/></small>
      <xsl:text>]</xsl:text>
    </xsl:element> 
  </xsl:template>

  <xsl:template name="add_id">
    <xsl:if test="@xml:id">
      <xsl:attribute name="id">
      	<xsl:value-of select="@xml:id"/>
      </xsl:attribute>
    </xsl:if>
  </xsl:template>

  <xsl:template name="img_ref">
    <xsl:if test="@facs">
      <xsl:attribute name="data-src">
	<xsl:value-of select="@facs"/>
      </xsl:attribute>
    </xsl:if>
    <xsl:attribute name="src">default.gif</xsl:attribute>
  </xsl:template>

</xsl:stylesheet>
