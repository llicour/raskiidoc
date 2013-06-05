<xsl:stylesheet version="1.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform" >

<!-- Redefinition du tag ~text~
<xsl:template name="inline.subscriptseq">
  <xsl:param name="content">
    <xsl:apply-templates/>
  </xsl:param>
  <xsl:text>{\tiny </xsl:text>
  <xsl:copy-of select="$content"/>
  <xsl:text>}</xsl:text>
</xsl:template>
-->

<!-- Redefinition du tag ^text^
<xsl:template name="inline.superscriptseq">
  <xsl:param name="content">
    <xsl:apply-templates/>
  </xsl:param>
  <xsl:text>{\scriptsize </xsl:text>
  <xsl:copy-of select="$content"/>
  <xsl:text>}</xsl:text>
</xsl:template>
-->

<!-- font size tiny -->
 <xsl:template match="phrase[@role='f--']">
  <xsl:param name="content">
    <xsl:apply-templates/>
  </xsl:param>
  <xsl:text>{\tiny </xsl:text>
  <xsl:copy-of select="$content"/>
  <xsl:text>}</xsl:text>
 </xsl:template>

<!-- font size scriptsize -->
 <xsl:template match="phrase[@role='f-']">
  <xsl:param name="content">
    <xsl:apply-templates/>
  </xsl:param>
  <xsl:text>{\scriptsize </xsl:text>
  <xsl:copy-of select="$content"/>
  <xsl:text>}</xsl:text>
 </xsl:template>

<!-- font size large -->
 <xsl:template match="phrase[@role='f1']">
  <xsl:param name="content">
    <xsl:apply-templates/>
  </xsl:param>
  <xsl:text>{\large </xsl:text>
  <xsl:copy-of select="$content"/>
  <xsl:text>}</xsl:text>
 </xsl:template>

<!-- font size huge -->
 <xsl:template match="phrase[@role='f2']">
  <xsl:param name="content">
    <xsl:apply-templates/>
  </xsl:param>
  <xsl:text>{\huge </xsl:text>
  <xsl:copy-of select="$content"/>
  <xsl:text>}</xsl:text>
 </xsl:template>

</xsl:stylesheet> 
