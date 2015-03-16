<?xml version="1.0" encoding="UTF-8" ?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	       xmlns:t="http://www.tei-c.org/ns/1.0"
	       xmlns="http://www.tei-c.org/ns/1.0"
	       exclude-result-prefixes="xsl t"
	       version="1.0">

  <xsl:output encoding="UTF-8"
	      indent="yes" />

  <xsl:template match="t:sourceDesc/t:bibl">
    <bibl>
      <xsl:copy-of select="@*"/>
      <title>Shit happens</title>
    </bibl>
  </xsl:template>

  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>
</xsl:transform>
