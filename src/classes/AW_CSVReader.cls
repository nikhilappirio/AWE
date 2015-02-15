public without sharing class AW_CSVReader {
  //  Csv Reader
  //
  private String     delim = ',';

  private String[]   buffer;              // the input data for entire CSV file
  
  private String rowDelim;

  //  ------------------------------
  //  Constructors
  //  ------------------------------
  public AW_CSVReader(String data){
  	this.rowDelim = setRowDelim(data);
    this.buffer = (data == null ? new List<String>() : data.split('\n'));
  }
  
  //  ------------------------------
  //  Constructors
  //  ------------------------------
  public AW_CSVReader(String data, Boolean isHeaderRequired){
  	this.rowDelim = setRowDelim(data);
    this.buffer = (data == null ? new List<String>() : data.split(rowDelim));
    System.debug('::this.buffer before'+this.buffer);
    System.debug('::this.buffer before'+this.buffer.size());
    if(!isHeaderRequired && this.buffer.size() > 0){
        this.buffer.remove(0);
    }
    System.debug('::this.buffer'+this.buffer);
  }

  public AW_CSVReader(String data, String delim){
  	this.rowDelim = setRowDelim(data);
    this.buffer = (data == null ? new List<String>() : data.split(rowDelim));
    this.delim = delim;
  }

  //  -------------------------------
  //  readLine - returns array of csv tokens as strings; reads through buffer, removing from buffer as each line is located in toto. Return null if end of stream.
  //  ------------------------------- 
  public String[] readLine(){
  	System.debug('::this.buffer readline'+this.buffer);
    if(this.buffer.size() == 0) return null;
    String     line     = this.buffer.remove(0).trim();    // grab first part of stream up to newline; remove from buffer
    String[]   parts     = new String[] {};        // result list of tokens for one line
    while(line != ''){
      Integer next = 0;
      if(line.startsWith('"')){
        line = line.substring(1); // strip initial "
        Integer quoteIndex = findQuote(line, 0);    // Look for closing " on same line
        while(quoteIndex == -1){            //  not found, we must have a newline within a quoted token
          if(buffer.size() == 0){
            // EOT!
            quoteIndex = line.length();
          } 
          else {
            // grab the next line and look to see if closing " can be found
            Integer skip = line.length();
            line += rowDelim + this.buffer.remove(0); // \n -> rowDelim
            quoteIndex = findQuote(line, skip);
          }
        }
        // we have a quoted token, advance to comma
        next = quoteIndex + 1;
        parts.add(line.substring(0, quoteIndex).replace('""', '"')); 
        } 
      else {    // non-quoted token, token end is at delim
        next = line.indexOf(this.delim, next);
        if(next == -1)
          next = line.length();
        // NB in Substring, "endindex" is the index of the character AFTER the last index to get
        parts.add(line.substring(0, next));
      }
      if(next == line.length() - 1)
      // case of a terminating comma.
        parts.add('');
      line = next < line.length() ? line.substring(next+1) : '';
    }
    return parts;
  }

  static private Pattern quotePattern = Pattern.compile('(?<!")"(?!")');

  //  -------------------------------------------------
  //  Helper: findQuote - find next quote " in line
  private Integer findQuote(String line, Integer skip){
    Matcher m = quotePattern.matcher(line);
    m.region(skip, m.regionEnd());
    if(!m.find())
      return -1;
    return m.start();
  }
  
  public String getRowDelim(){
  	return rowDelim;
  }
  
  public String[] getData(){
  	return buffer;
  }
  public String setRowDelim(String csvBody){
  	if(csvBody != null){
	  	if(csvBody.contains('\t')){
	  		return '\t';
	  	}else if(csvBody.contains('\r')){
	  		return '\r';
	  	}
  	}
	return '\n';
  }
}