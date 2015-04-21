<?xml version="1.0" encoding="UTF-8" ?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	       xmlns:t="http://www.tei-c.org/ns/1.0"
	       xmlns="http://www.w3.org/1999/xhtml"
	       version="1.0">

  <xsl:output method="xml"
	      encoding="UTF-8"
	      omit-xml-declaration="yes"/>

  <xsl:template match="/t:TEI">
    <html>
      <xsl:apply-templates mode="head" select="t:teiHeader"/>
      <body>
	<h3><xsl:apply-templates mode="body" select="t:teiHeader"/></h3>
	<xsl:apply-templates select="t:text"/>
      </body>
    </html>
  </xsl:template>

  <xsl:template mode="body" match="t:teiHeader">
    <xsl:for-each select="t:fileDesc/t:sourceDesc/t:bibl[1]">
      <xsl:for-each select="t:author">
	<span property="author">
	  <xsl:choose>
	    <xsl:when test="position() = 1">
	      <xsl:value-of select="t:name/t:surname"/><xsl:text>,
	      </xsl:text><xsl:value-of select="t:name/t:forename"/>
	    </xsl:when>
	    <xsl:otherwise>
	      <xsl:choose>
		<xsl:when test="position() = last()">
		  <xsl:text> &amp; </xsl:text>
		</xsl:when>
		<xsl:otherwise>
		  <xsl:text>, </xsl:text>
		</xsl:otherwise>
	      </xsl:choose>
	      <xsl:value-of select="t:name/t:forename"/><xsl:text>
	      </xsl:text><xsl:value-of select="t:name/t:surname"/>
	    </xsl:otherwise>
	  </xsl:choose>
	</span>
      </xsl:for-each>
      <xsl:if test="t:date">
	(<span property="datePublished">
	  <xsl:value-of select="t:date"/>
	</span><xsl:text>) </xsl:text>
      </xsl:if>
     <xsl:if test="t:title">
       <em property="name">
	 <xsl:value-of 
	     select="t:title[not(@type)]"/>
	 <xsl:if test="t:title[@type='sub']">
	   <xsl:text>: </xsl:text><xsl:value-of 
	       select="t:title[@type='sub']"/>
	 </xsl:if>
       </em>
     </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <xsl:template mode="head" match="t:teiHeader">
    <head>
      <title>
	<xsl:value-of 
	    select="t:fileDesc/t:sourceDesc/t:bibl/t:title[not(@type)]"/>
      </title>
      <meta http-equiv="content-type" 
	    content="application/xhtml+xml; charset=UTF-8"/>
      <xsl:call-template name="scripts"/>
    </head>
  </xsl:template>

  <xsl:template match="t:text">
    <xsl:apply-templates select="t:body"/>
  </xsl:template>

  <xsl:template match="t:body">
    <ul style="list-style-type: none">
      <xsl:for-each select="//t:div[@n &lt; 5 ]">
	<li title="click to select">
	  <xsl:attribute name="onclick"> 
	    <xsl:text>closeopen('</xsl:text>
	    <xsl:value-of select="concat('letter',@xml:id)"/>
	    <xsl:text>')</xsl:text>
	  </xsl:attribute>
	<strong><xsl:value-of select="@n"/></strong><xsl:text>
	</xsl:text><xsl:call-template name="letter_title"/>
	</li>
      </xsl:for-each>
    </ul>
    <xsl:for-each select="//t:div[@n &lt; 5 ]">
      <div style="display: none;">
	<xsl:attribute name="id"><xsl:value-of
	select="concat('letter',@xml:id)"/></xsl:attribute>
	<div style="width:45%;float:left;">
	  <form>
	    <dl>
	      <xsl:call-template name="render_form"/>
	    </dl>
	  </form>
	  <xsl:apply-templates/>
	</div>
	<div style="margin-left:+2em; width:45%;float:left;">
	  <xsl:for-each select="preceding::t:pb[1]|descendant::t:pb">
	    <xsl:call-template name="render_facs"/>
	  </xsl:for-each>
	</div>
      </div>
    </xsl:for-each>
  </xsl:template>

  <!--
   1. Start
   2. Brevskrivningsdato
   3. Afsender
   4. Afsendelsessted
   5. Modtager
   6. Modtagelsessted
   7. Sprog – er angivet i selve softwaren og derfor ikke opmærket på samme
   måde som resten. Kan findes i tagget <w:lang> under attribute
   w:val=””. Følger iso-forkortelser, så vidt jeg kan regne ud.
   8. Proveniens
   9. Note
  10. Slut
  -->  

  <xsl:template match="t:opener">
    <xsl:apply-templates select="t:dateline"/>
    <xsl:apply-templates select="t:salute"/>
  </xsl:template>

  <xsl:template match="t:closer">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="t:postscript">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="t:signed">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="t:salute/t:persName">
    <span property="recipient">
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <xsl:template match="t:signed/t:persName">
    <span property="author">
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <xsl:template match="t:dateline">
    <p style="text-align: right;">
      <xsl:if test="t:geogName">
	<xsl:apply-templates select="t:geogName"/>
	<xsl:if test="t:date"><br/></xsl:if>
      </xsl:if>
      <xsl:if test="t:date">
	<xsl:apply-templates select="t:date"/>
      </xsl:if>
    </p>
  </xsl:template>

  <xsl:template match="t:salute">
    <p>
      <xsl:apply-templates/>
    </p>
  </xsl:template>

  <xsl:template match="t:date">
    <xsl:element name="span">
      <xsl:attribute name="property">datePublished</xsl:attribute>
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="t:p">
    <xsl:element name="p">
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="t:pb">
    [s. <a href="#{@xml:id}"><xsl:value-of select="@n"/></a>]
  </xsl:template>

  <xsl:template name="inputfield">
    <xsl:param name="variable" select="'shit'"/>
    <xsl:param name="value"    select="''"/>
    <dd>
      <xsl:element name="input">
	<xsl:attribute name="name">
	  <xsl:value-of select="$variable"/>
	</xsl:attribute>
	<xsl:attribute name="value">
	  <xsl:value-of select="$value"/>
	</xsl:attribute>
      </xsl:element>
    </dd>
  </xsl:template>

  <xsl:template name="render_input">
    <xsl:param name="xpath"/>
    <xsl:param name="variable" select="'shit'"/>
    <xsl:choose>
      <xsl:when test="$xpath">
	<xsl:for-each select="$xpath">
	  <xsl:call-template name="inputfield">
	    <xsl:with-param name="variable" select="$variable"/>
	    <xsl:with-param name="value" select="."/>
	  </xsl:call-template>
	</xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
	<xsl:call-template name="inputfield">
	  <xsl:with-param name="variable" select="$variable"/>
	</xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="render_form">
    <dt>Afsender</dt>
    <xsl:call-template name="render_input">
      <xsl:with-param name="xpath" select="t:closer/t:signed/t:persName"/>
      <xsl:with-param name="variable">sender</xsl:with-param>
    </xsl:call-template>

    <dt>Afsendelsessted</dt>
    <xsl:call-template name="render_input">
      <xsl:with-param name="xpath" select="t:opener/t:dateline/t:geogName"/>
      <xsl:with-param name="variable">senders_place</xsl:with-param>
    </xsl:call-template>

    <dt>Brevskrivningsdato</dt>
    <xsl:call-template name="render_input">
      <xsl:with-param name="xpath" select="t:opener/t:dateline/t:date"/>
      <xsl:with-param name="variable">date</xsl:with-param>
    </xsl:call-template>

    <dt>Modtager</dt>
    <xsl:call-template name="render_input">
      <xsl:with-param name="xpath" select="t:opener/t:salute/t:persName"/>
      <xsl:with-param name="variable">recipient</xsl:with-param>
    </xsl:call-template>
 
    <dt>Modtagelsessted</dt>
    <xsl:call-template name="render_input">
      <xsl:with-param name="xpath" select="t:opener/t:address/t:addrLine"/>
      <xsl:with-param name="variable">recipients_place</xsl:with-param>
    </xsl:call-template>

  </xsl:template>

  <xsl:template name="render_facs">
    <xsl:element name="img">
      <xsl:attribute name="style">
	width:100%;
      </xsl:attribute>
      <xsl:attribute name="id">
	<xsl:value-of select="@xml:id"/>
      </xsl:attribute>
      <xsl:attribute name="alt">
	side <xsl:value-of select="@n"/>
      </xsl:attribute>
      <xsl:attribute name="src">
	<xsl:value-of select="@facs"/>
      </xsl:attribute>
    </xsl:element>
  </xsl:template>

  <xsl:template name="letter_title">
    <span>
      <xsl:for-each 
	  select="t:opener/t:dateline/t:geogName |
		  t:opener/t:dateline/t:date">
	<xsl:apply-templates select="."/>
	<xsl:if test="position()=last()">. </xsl:if>
	<xsl:text> </xsl:text>
      </xsl:for-each>
      <xsl:for-each 
	  select="t:opener/t:salute/t:persName"> 
	<xsl:if test="position()=1">Til </xsl:if>
	<xsl:apply-templates select="."/><xsl:text> </xsl:text>
      </xsl:for-each>

      <xsl:for-each 
	  select="t:closer/t:signed/t:persName">
	<xsl:if test="position()=1">fra </xsl:if>
	<xsl:apply-templates select="."/>
      </xsl:for-each>
    </span>

  </xsl:template>

  <xsl:template name="scripts">
    <script type="application/javascript">
      <xsl:text>
	opendiv = "";
	function closeopen(lid) {
	   if(opendiv) {
	      prevlet = document.getElementById(opendiv);
   	      prevlet.style.display="none";
	   }
	   var letter = document.getElementById(lid);
	   letter.style.display="block";
	   opendiv = lid;
	}
      </xsl:text>
    </script>
  </xsl:template>
  
</xsl:transform>
