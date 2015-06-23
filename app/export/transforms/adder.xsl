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

  <xsl:variable name="volume_title" select="t:TEI/t:teiHeader/t:fileDesc/t:titleStmt/t:title"/>
  <xsl:variable name="author" select="t:TEI/t:teiHeader/t:fileDesc/t:titleStmt/t:author"/>

  <xsl:template match="/">
    <xsl:element name="add">
      <xsl:apply-templates select="//t:div[@decls]|//t:text[@decls]"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="t:text[@decls]|t:div[@decls]">
    <xsl:variable name="bibl" select="substring-after(@decls,'#')"/>
    <xsl:variable name="workid" select="concat($file,'#',@xml:id)"/>
    <xsl:variable name="worktitle">
      <xsl:apply-templates
	  select="/t:TEI/t:teiHeader/t:fileDesc/t:sourceDesc/t:listBibl/t:bibl[@xml:id=$bibl]"/>
    </xsl:variable>

    <doc>
      <xsl:element name="field"><xsl:attribute name="name">type</xsl:attribute>trunk</xsl:element>
      
      <xsl:element name="field">
	<xsl:attribute name="name">work_title</xsl:attribute>
	<xsl:value-of  select="$worktitle"/>
      </xsl:element>

      <xsl:call-template name="add_globals"/>     

      <xsl:element name="field">
	<xsl:attribute name="name">text</xsl:attribute>
	  <xsl:apply-templates select="descendant::text()"/>
      </xsl:element>
    </doc>
    <xsl:for-each select="descendant::t:div/t:p|
                          descendant::t:lg|
                          descendant::t:sp">
      <xsl:apply-templates select=".">
	<xsl:with-param name="workid" select="$workid"/>
	<xsl:with-param name="worktitle" select="$worktitle"/>
      </xsl:apply-templates>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="t:sp">
    <xsl:param name="workid" select="''"/>
    <xsl:param name="worktitle" select="''"/>

    <doc>

      <xsl:element name="field"><xsl:attribute name="name">type</xsl:attribute>leaf</xsl:element>

      <xsl:if test="$workid">
	<xsl:element name="field">
	  <xsl:attribute name="name">part_of</xsl:attribute>
	  <xsl:value-of select="$workid"/>
	</xsl:element>
      </xsl:if>

      <xsl:call-template name="add_globals"/>
      
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
    <xsl:param name="workid" select="''"/>
    <xsl:param name="worktitle" select="''"/>

    <doc>

      <xsl:element name="field"><xsl:attribute name="name">type</xsl:attribute>leaf</xsl:element>

      <xsl:if test="$workid">
	<xsl:element name="field">
	  <xsl:attribute name="name">part_of</xsl:attribute>
	  <xsl:value-of select="$workid"/>
	</xsl:element>
      </xsl:if>

      <xsl:call-template name="add_globals"/>
     
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

    <xsl:param name="workid" select="''"/>
    <xsl:param name="worktitle" select="''"/>

    <doc>

      <xsl:element name="field"><xsl:attribute name="name">type</xsl:attribute>leaf</xsl:element>

      <xsl:if test="$workid">
	<xsl:element name="field">
	  <xsl:attribute name="name">part_of</xsl:attribute>
	  <xsl:value-of select="$workid"/>
	</xsl:element>
      </xsl:if>

      <xsl:call-template name="add_globals"/>

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

  <xsl:template name="add_globals">
    <xsl:element name="field">
      <xsl:attribute name="name">id</xsl:attribute>
      <xsl:value-of select="concat($file,'#',@xml:id)"/>
    </xsl:element>

    <xsl:element name="field">
      <xsl:attribute name="name">url</xsl:attribute>
      <xsl:value-of select="concat($url,'#',@xml:id)"/>
    </xsl:element>

      <xsl:element name="field">
	<xsl:attribute name="name">volume_title</xsl:attribute>
	<xsl:value-of select="$volume_title"/>
      </xsl:element>

      <xsl:if test="t:head|../t:head">
	<xsl:element name="field">
	  <xsl:attribute name="name">head</xsl:attribute>
	  <xsl:value-of select="t:head|../t:head[1]"/>
	</xsl:element>
      </xsl:if>

      <xsl:element name="field">
	<xsl:attribute name="name">author</xsl:attribute>
	<xsl:value-of select="$author"/>
      </xsl:element>

  </xsl:template>


</xsl:transform>
