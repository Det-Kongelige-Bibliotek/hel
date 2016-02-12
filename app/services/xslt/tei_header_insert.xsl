<?xml version="1.0" encoding="UTF-8" ?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	       xmlns:t="http://www.tei-c.org/ns/1.0"
	       xmlns="http://www.tei-c.org/ns/1.0"
	       xmlns:my="http://example.com/functions" 
	       extension-element-prefixes="my"
	       exclude-result-prefixes="my xsl t"
	       version="1.0">

  <!--
      This XSL inserts data into the teiHeader, assuming the presence of a
      rudimentary header.
  -->
  <xsl:include href="common_functions.xsl" />

  <xsl:output method="xml"
	      indent="yes"
	      encoding="UTF-8" />



  <xsl:template match="t:sourceDesc/t:bibl">
    <bibl>
      <xsl:apply-templates select="@*"/>
      <xsl:call-template name="author" />
      <xsl:call-template name="title" />
      <xsl:call-template name="date" />
      <xsl:call-template name="publisher" />
      <xsl:call-template name="pub_place" />
    </bibl>
  </xsl:template>

  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

</xsl:transform>
