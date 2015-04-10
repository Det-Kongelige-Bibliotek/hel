<?xml version="1.0" encoding="UTF-8" ?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	       xmlns:t="http://www.tei-c.org/ns/1.0"
	       xmlns="http://www.tei-c.org/ns/1.0"
	       xmlns:my="http://example.com/functions" 
	       extension-element-prefixes="my"
	       exclude-result-prefixes="my xsl t"
	       version="1.0">

  <xsl:include href="common_functions.xsl" />

  <xsl:template match="t:sourceDesc/t:bibl">
    <bibl>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates 
	  mode="bibl" 
	  select="t:pubPlace|t:date|t:publisher|t:title[1]|t:author[1]"/>
      <xsl:apply-templates
	  select="t:editor|t:ref|t:relatedItem|t:respStmt|t:textLang"/>
    </bibl>
  </xsl:template>

  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

</xsl:transform>
