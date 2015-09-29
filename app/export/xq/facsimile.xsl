<?xml version="1.0" encoding="UTF-8" ?>

<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:t="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="t"
    version="1.0">

  <xsl:param name="id" select="''"/>
  <xsl:param name="doc" select="''"/>
  <xsl:param name="prefix" select="'http://kb-images.kb.dk/public/'"/>

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

	  <xsl:for-each select="//node()[@xml:id=$id]/preceding::t:pb[1]|//node()[@xml:id=$id]//t:pb">
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
      <xsl:call-template name="img_ref"/>
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
    <xsl:choose>
      <xsl:when test="contains(@facs,'http') and not(contains(@rend,'missing'))">
        <xsl:element name="img">
      <xsl:attribute name="data-src">
        <xsl:value-of select="concat(@facs,'/full/full/0/native.jpg')"/>
      </xsl:attribute>
      <xsl:attribute name="src">
      </xsl:attribute>
        </xsl:element>
      </xsl:when>
      <xsl:when test="not(contains(@facs,'http')) and not(contains(@rend,'missing'))">
        <xsl:element name="img">
          <xsl:attribute name="data-src">
            <xsl:value-of select="concat($prefix,@facs,'/full/full/0/native.jpg')"/>
          </xsl:attribute>
          <xsl:attribute name="src">
          </xsl:attribute>
        </xsl:element>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
