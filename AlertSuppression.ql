/**
 * @name Alert suppression
 * @description Generates information about alert suppressions.
 * @kind alert-suppression
 * @id cpp/alert-suppression
 */

 import cpp

 /**
  * Gets the text of a comment, excluding delimiters.
  */
 string getCommentText(Comment c) {
   c instanceof CppStyleComment and
   result = c.getContents().suffix(2)
   or
   c instanceof CStyleComment and
   exists(string text0 |
     text0 = c.getContents().suffix(2) and
     result = text0.prefix(text0.length() - 2) and
     // Must be single-line
     not result.matches("%\n%")
   )
 }
 
 /**
  * An alert suppression comment.
  */
 abstract class SuppressionComment extends Comment {
   /** Gets the suppression annotation in this comment. */
   abstract string getAnnotation();
 
   /**
    * Holds if this comment applies to the range from column `startcolumn` of line `startline`
    * to column `endcolumn` of line `endline` in file `filepath`.
    */
   abstract predicate covers(
     string filepath, int startline, int startcolumn, int endline, int endcolumn
   );
 
   /** Gets the scope of this suppression. */
   SuppressionScope getScope() { result = this }
 
   /** Gets the text in this comment, excluding the leading //. */
   string getText() { result = getCommentText(this) }
 }
 
 /**
  * An LGTM-style suppression comment.
  */
 class LgtmSuppressionComment extends SuppressionComment {
   private string annotation;
 
   LgtmSuppressionComment() {
     exists(string text | text = getCommentText(this) |
       // match `lgtm[...]` anywhere in the comment
       annotation = text.regexpFind("(?i)\\blgtm\\s*\\[[^\\]]*\\]", _, _)
       or
       // match `lgtm` at the start of the comment and after semicolon
       annotation = text.regexpFind("(?i)(?<=^|;)\\s*lgtm(?!\\B|\\s*\\[)", _, _).trim()
     )
   }
 
   override string getAnnotation() { result = annotation }
 
   override predicate covers(
     string filepath, int startline, int startcolumn, int endline, int endcolumn
   ) {
     exists(int commentLine |
       this.getLocation().hasLocationInfo(filepath, commentLine, _, commentLine, _) and
       (
         // Cover the comment line itself
         startline = commentLine and
         endline = commentLine and
         startcolumn = 1 and
         endcolumn = this.getLocation().getEndColumn()
         or
         // Cover the entire next line
         startline = commentLine + 1 and
         endline = commentLine + 1 and
         startcolumn = 1 and
         endcolumn = 200
       )
     )
   }
 }
 
 /**
  * A CodeQL-style suppression comment.
  */
 class CodeQlSuppressionComment extends SuppressionComment {
   private string annotation;
 
   CodeQlSuppressionComment() {
     exists(string text | text = getCommentText(this) |
       // match `codeql[...]` anywhere in the comment
       annotation = text.regexpFind("(?i)\\bcodeql\\s*\\[[^\\]]*\\]", _, _)
     )
   }
 
   override string getAnnotation() {
     // Convert codeql[...] to lgtm[...] format for CodeQL engine compatibility
     result = "lgtm" + annotation.suffix(6)
   }
 
   override predicate covers(
     string filepath, int startline, int startcolumn, int endline, int endcolumn
   ) {
     exists(int commentLine |
       this.getLocation().hasLocationInfo(filepath, commentLine, _, commentLine, _) and
       (
         // Cover the comment line itself
         startline = commentLine and
         endline = commentLine and
         startcolumn = 1 and
         endcolumn = this.getLocation().getEndColumn()
         or
         // Cover the entire next line
         startline = commentLine + 1 and
         endline = commentLine + 1 and
         startcolumn = 1 and
         endcolumn = 200
       )
     )
   }
 }
 
 /**
  * A GSec-style suppression comment.
  */
 class GSecSuppressionComment extends SuppressionComment {
   private string annotation;
 
   GSecSuppressionComment() {
     exists(string text | text = getCommentText(this) |
       // match `gsec[...]` anywhere in the comment
       annotation = text.regexpFind("(?i)\\bgsec\\s*\\[[^\\]]*\\]", _, _)
     )
   }
 
   override string getAnnotation() {
     // Convert gsec[...] to lgtm[...] format for CodeQL engine compatibility
     result = "lgtm" + annotation.suffix(4)
   }
 
   override predicate covers(
     string filepath, int startline, int startcolumn, int endline, int endcolumn
   ) {
     exists(int commentLine |
       this.getLocation().hasLocationInfo(filepath, commentLine, _, commentLine, _) and
       (
         // Cover the comment line itself
         startline = commentLine and
         endline = commentLine and
         startcolumn = 1 and
         endcolumn = this.getLocation().getEndColumn()
         or
         // Cover the entire next line
         startline = commentLine + 1 and
         endline = commentLine + 1 and
         startcolumn = 1 and
         endcolumn = 200
       )
     )
   }
 }
 
 /**
  * The scope of an alert suppression comment.
  */
 class SuppressionScope extends ElementBase instanceof SuppressionComment {
   /**
    * Holds if this element is at the specified location.
    * The location spans column `startcolumn` of line `startline` to
    * column `endcolumn` of line `endline` in file `filepath`.
    */
   predicate hasLocationInfo(
     string filepath, int startline, int startcolumn, int endline, int endcolumn
   ) {
     super.covers(filepath, startline, startcolumn, endline, endcolumn)
   }
 
   /** Gets a textual representation of this element. */
   override string toString() { result = "suppression range" }
 }
 
 from SuppressionComment c
 select c, // suppression comment
   c.getText(), // text of suppression comment (excluding delimiters)
   c.getAnnotation(), // text of suppression annotation
   c.getScope() // scope of suppression