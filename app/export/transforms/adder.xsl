<?xml version="1.0" encoding="UTF-8" ?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	       xmlns:t="http://www.tei-c.org/ns/1.0"
	       exclude-result-prefixes="t"
	       version="1.0">

  <!-- not a poisonous adder -->

  <xsl:output indent="yes"
	      encoding="UTF-8"
	      method="xml"/>

  <xsl:param name="file" select="''"/>
  <xsl:param name="uri_base"  select="'http://udvikling.kb.dk/'"/>
  <xsl:param name="url"       select="concat($uri_base,$file)"/>

  <xsl:variable name="title" select="t:TEI/t:teiHeader/t:fileDesc/t:titleStmt/t:title"/>
  <xsl:variable name="author" select="t:TEI/t:teiHeader/t:fileDesc/t:titleStmt/t:author"/>

  <xsl:template match="/">
    <xsl:element name="add">
      <xsl:apply-templates select="//t:body|//t:group|//t:text"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="t:group|t:text|t:body">
    <xsl:for-each select="//t:div/t:p|//t:lg|//t:sp">
      <xsl:apply-templates select="."/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="t:sp">
    <doc>
      <xsl:element name="field">
	<xsl:attribute name="name">id</xsl:attribute>
	<xsl:value-of select="concat($file,'#',@xml:id)"/>
      </xsl:element>

      <xsl:element name="field">
	<xsl:attribute name="name">url</xsl:attribute>
	<xsl:value-of select="concat($url,'#',@xml:id)"/>
      </xsl:element>

      <xsl:element name="field">
	<xsl:attribute name="name">title</xsl:attribute>
	<xsl:value-of select="$title"/>
      </xsl:element>

      <xsl:if test="t:head|../t:head">
	<xsl:element name="field">
	  <xsl:attribute name="name">title</xsl:attribute>
	  <xsl:value-of select="t:head|../t:head[1]"/>
	</xsl:element>
      </xsl:if>

      <xsl:element name="field">
	<xsl:attribute name="name">author</xsl:attribute>
	<xsl:value-of select="$author"/>
      </xsl:element>

      <xsl:element name="field">
	<xsl:attribute name="name">cat</xsl:attribute>
	<xsl:text>play</xsl:text>
      </xsl:element>

      <xsl:element name="field">
	<xsl:attribute name="name">speaker</xsl:attribute>
	<xsl:value-of select="t:speaker"/>
      </xsl:element>

      <xsl:element name="field">
      <xsl:attribute name="name">text</xsl:attribute>
      <xsl:apply-templates select="t:p"/>
      </xsl:element>

    </doc>
  </xsl:template>


  
  <xsl:template match="t:lg">
    <doc>
      <xsl:element name="field">
	<xsl:attribute name="name">id</xsl:attribute>
	<xsl:value-of select="concat($file,'#',@xml:id)"/>
      </xsl:element>

      <xsl:element name="field">
	<xsl:attribute name="name">url</xsl:attribute>
	<xsl:value-of select="concat($url,'#',@xml:id)"/>
      </xsl:element>

      <xsl:element name="field">
	<xsl:attribute name="name">title</xsl:attribute>
	<xsl:value-of select="$title"/>
      </xsl:element>

      <xsl:if test="t:head|../t:head">
	<xsl:element name="field">
	  <xsl:attribute name="name">title</xsl:attribute>
	  <xsl:value-of select="t:head|../t:head[1]"/>
	</xsl:element>
      </xsl:if>

      <xsl:element name="field">
	<xsl:attribute name="name">author</xsl:attribute>
	<xsl:value-of select="$author"/>
      </xsl:element>

      <xsl:element name="field">
	<xsl:attribute name="name">cat</xsl:attribute>
	<xsl:text>poetry</xsl:text>
      </xsl:element>

      <xsl:for-each select="t:l">
	<xsl:element name="field"><xsl:attribute name="name">text</xsl:attribute><xsl:apply-templates/></xsl:element>
      </xsl:for-each>
    </doc>
  </xsl:template>

  <xsl:template match="t:div/t:p">
    <doc>

      <xsl:element name="field">
	<xsl:attribute name="name">id</xsl:attribute>
	<xsl:value-of select="concat($file,'#',@xml:id)"/>
      </xsl:element>

      <xsl:element name="field">
	<xsl:attribute name="name">url</xsl:attribute>
	<xsl:value-of select="concat($url,'#',@xml:id)"/>
      </xsl:element>

      <xsl:element name="field">
	<xsl:attribute name="name">title</xsl:attribute>
	<xsl:value-of select="$title"/>
      </xsl:element>

      <xsl:if test="t:head|../t:head">
	<xsl:element name="field">
	  <xsl:attribute name="name">title</xsl:attribute>
	  <xsl:value-of select="t:head|../t:head[1]"/>
	</xsl:element>
      </xsl:if>

      <xsl:element name="field">
	<xsl:attribute name="name">author</xsl:attribute>
	<xsl:value-of select="$author"/>
      </xsl:element>

      <xsl:element name="field">
	<xsl:attribute name="name">cat</xsl:attribute>
	<xsl:text>prose</xsl:text>
      </xsl:element>

      <xsl:element name="field">
	<xsl:attribute name="name">text</xsl:attribute>
	<xsl:apply-templates/>
      </xsl:element>
    </doc>
  </xsl:template>

  <xsl:template match="node()">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="text()"><xsl:value-of select="normalize-space(.)"/><xsl:text>
</xsl:text></xsl:template>

</xsl:transform>
