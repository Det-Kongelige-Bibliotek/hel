<?xml version="1.0" encoding="UTF-8" ?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	       xmlns:t="http://www.tei-c.org/ns/1.0"
	       xmlns:str="http://exslt.org/strings"
               extension-element-prefixes="str"
	       exclude-result-prefixes="t"
	       version="1.0">

  <xsl:output method="xml"
	      indent="yes"
	      encoding="UTF-8"/>

  <xsl:template match="t:*">
    <xsl:element name="{name()}">
      <xsl:if test="not(@xml:id)">
        <xsl:attribute name="xml:id">
	  <xsl:value-of select="generate-id(.)"/>
	</xsl:attribute>
      </xsl:if>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="@*">
    <xsl:variable name="attribute" select="name(.)"/>
    <xsl:if test="not(name(.) = 'id')">
      <xsl:attribute name="{$attribute}">
	<xsl:value-of select="."/>
      </xsl:attribute>
   </xsl:if>
  </xsl:template>

  <xsl:template match="token"><xsl:text>
</xsl:text><xsl:element name="w">
      <xsl:attribute name="xml:id"><xsl:value-of select="concat('w',generate-id(.))"/></xsl:attribute>
      <xsl:value-of select="normalize-space(.)"/>
    </xsl:element></xsl:template>

  <xsl:template match="t:p/text()">
    <xsl:apply-templates select="str:tokenize(.)"/>
  </xsl:template>


</xsl:transform>

