<?xml version="1.0" encoding="UTF-8" ?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	       xmlns:t="http://www.tei-c.org/ns/1.0"
	       xmlns="http://www.tei-c.org/ns/1.0"
	       xmlns:my="http://example.com/functions" 
	       extension-element-prefixes="my"
	       exclude-result-prefixes="my xsl t"
	       version="1.0">

  <xsl:param name="aid" select="''"/>

<!-- 
     This terrible list of param elements is due to the fact valhal cannot do
     a decent xml serialization of the metadata, that I and ruby nokogiri
     just don't understand each other, or possibly that nokogiri is just garbage. I
     don't preclude any of the former. 
-->

<!-- pairs of first and last names -->

  <xsl:param name="first0" select="''"/>
  <xsl:param name="last0" select="''"/>

  <xsl:param name="first1" select="''"/>
  <xsl:param name="last1" select="''"/>

  <xsl:param name="first2" select="''"/>
  <xsl:param name="last2" select="''"/>

<!-- pairs of titles and subtitles -->

  <xsl:param name="title0" select="''"/>
  <xsl:param name="title1" select="''"/>
  <xsl:param name="title2" select="''"/>
  <xsl:param name="title3" select="''"/>

  <xsl:param name="sub_title0" select="''"/>
  <xsl:param name="sub_title1" select="''"/>
  <xsl:param name="sub_title2" select="''"/>
  <xsl:param name="sub_title3" select="''"/>

<!-- some other fields -->

  <xsl:param name="date" select="''"/>
  <xsl:param name="publisher" select="''"/>
  <xsl:param name="pub_place" select="''"/>
                  
  <xsl:output encoding="UTF-8"
	      indent="yes" />

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

  <xsl:template mode="bibl" match="t:pubPlace">
    <pubPlace>
      <xsl:copy-of select="@*"/>
      <xsl:choose>
	<xsl:when test="$pub_place">
	  <xsl:value-of select="$pub_place"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:apply-templates/>
	</xsl:otherwise>
      </xsl:choose>
    </pubPlace>
  </xsl:template>

  <xsl:template mode="bibl" match="t:date">
    <date>
      <xsl:copy-of select="@*"/>
      <xsl:choose>
	<xsl:when test="$date">
	  <xsl:value-of select="$date"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:apply-templates/>
	</xsl:otherwise>
      </xsl:choose>
    </date>
  </xsl:template>

  <xsl:template mode="bibl" match="t:publisher">
    <publisher>
      <xsl:copy-of select="@*"/>
      <xsl:value-of select="$publisher"/>
    </publisher>
  </xsl:template>

  <xsl:template mode="bibl" match="t:title">
    <xsl:if test="$title0">
      <xsl:element name="title">
	<xsl:copy-of select="@*"/>
	<xsl:value-of select="$title0"/>
      </xsl:element>
      <xsl:if test="$sub_title0">
	<xsl:call-template name="encode_title">
	  <xsl:with-param name="type" select="'sub'"/>
	  <xsl:with-param name="tit" select="$sub_title0"/>
	</xsl:call-template>
      </xsl:if>
    </xsl:if>
    <xsl:if test="$title1">
      <xsl:call-template name="encode_title">
	<xsl:with-param name="tit" select="$title1"/>
      </xsl:call-template>
      <xsl:if test="$sub_title1">
	<xsl:call-template name="encode_title">
	  <xsl:with-param name="type" select="'sub'"/>
	  <xsl:with-param name="tit" select="$sub_title1"/>
	</xsl:call-template>
      </xsl:if>
    </xsl:if>
    <xsl:if test="$title2">
      <xsl:call-template name="encode_title">
	<xsl:with-param name="tit" select="$title2"/>
      </xsl:call-template>
      <xsl:if test="$sub_title2">
	<xsl:call-template name="encode_title">
	  <xsl:with-param name="type" select="'sub'"/>
	  <xsl:with-param name="tit" select="$sub_title2"/>
	</xsl:call-template>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <xsl:template name="encode_title">
    <xsl:param name="tit"/>
    <xsl:param name="type" select="''"/>
    <xsl:element name="title">
      <xsl:if test="$type">
	<xsl:attribute name="type">
	  <xsl:value-of select="$type"/>
	</xsl:attribute>
      </xsl:if>
      <xsl:value-of select="$tit"/>
    </xsl:element>
  </xsl:template>


  <xsl:template mode="bibl" match="t:author">
    <xsl:if test="$last0 and $first0">
      <xsl:call-template name="encode_aut">
	<xsl:with-param name="autfirst" select="$first0" />
	<xsl:with-param name="autlast"  select="$last0"  />
      </xsl:call-template>
    </xsl:if>
    <xsl:if test="$last1 and $first1">
      <xsl:call-template name="encode_aut">
	<xsl:with-param name="autfirst" select="$first1" />
	<xsl:with-param name="autlast"  select="$last1"  />
      </xsl:call-template>
    </xsl:if>
    <xsl:if test="$last2 and $first2">
      <xsl:call-template name="encode_aut">
	<xsl:with-param name="autfirst" select="$first2" />
	<xsl:with-param name="autlast"  select="$last2"  />
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <xsl:template name="encode_aut">
    <xsl:param name="autfirst"/>
    <xsl:param name="autlast"/>
    <author>
      <name>
	<surname><xsl:value-of select="$autlast"/></surname>,
	<forename><xsl:value-of select="$autfirst"/></forename>
      </name>
    </author>
  </xsl:template>


  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>
</xsl:transform>
