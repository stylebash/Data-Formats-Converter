/************************************************************************
 * Data Formats Converter
 * Currently available conversion formats:
 * - json to jsonl
 * - jsonl to json
 * 
 * @description A collection of functions to convert between data formats
 * @author 
 * @date 2026/09/20
 * @version 1.0.0
 ***********************************************************************/

class DFC {

  /**
   * Read from a .json file to copy and create to a new .jsonL file. i.e. Convert.
   * @param firstFile string Convert from this .json file
   * @param secondFile string Convert to this .jsonL file
   * @returns bool True for successful conversion, False for failure
   */
  static JsonToJsonl(firstFile := "jsonFile.json", secondFile := "jsonLFile.jsonl") {
      ; Guard 1: Verify input file exists
      if !FileExist(firstFile) {
          OutputDebug("Error: Input file does not exist -> " . firstFile)
          return false
      }

      tempFile := secondFile . ".tmp"
      
      ; Ensure old temporary files are cleaned up before starting
      if FileExist(tempFile) 
        try FileDelete(tempFile)
      

      outFile := 0
      
      try {
          ; Guard 2: Safe opening of temporary write file
          outFile := FileOpen(tempFile, "w", "UTF-8")
          if !IsObject(outFile) {
              OutputDebug("Error: Failed to create temporary file -> " . tempFile)
              return false
          }

          bufferLine := ""
          depth := 0
          inRootArray := false
          writtenObjectsCount := 0

          Loop Read, firstFile
          {
              line := Trim(A_LoopReadLine)
              
              ; Skip empty lines
              if (line == "")
                continue
                  
              ; Detect start of root JSON array
              if (!inRootArray && line == "[") {
                  inRootArray := true
                  continue
              }
              
              ; Detect closing of root JSON array
              if (inRootArray && depth == 0 && line == "]") 
                break
              

              ; Append line to current object buffer
              bufferLine .= line "`n"

              ; Count opening/closing brackets and braces
              For char in StrSplit(line) {
                  if (char == "{" || char == "[")
                      depth++
                  else if (char == "}" || char == "]")
                      depth--
              }

              ; When depth hits 0, a root object is complete
              if (depth == 0 && bufferLine != "") {
                  cleanBuffer := RegExReplace(Trim(bufferLine), ",$", "")

                  ; Guard 3: Validate and parse JSON chunk
                  try {
                      jsonObject := JSON.Load(cleanBuffer)
                      minifiedLine := JSON.Dump(jsonObject)
                      outFile.WriteLine(minifiedLine)
                      writtenObjectsCount++
                  } catch Error as err {
                      OutputDebug("JSON Parsing Error on block:`n" . cleanBuffer . "`n`nError: " . err.Message)
                      throw err ; Bubble error up to abort conversion
                  }

                  bufferLine := ""
              }
          }

          ; Guard 4: Validate file structural integrity
          if (!inRootArray) 
              throw Error("Invalid format: Root array opening '[' was not found.")
          
          if (depth != 0 || bufferLine != "") 
              throw Error("Invalid format: Syntax error or unclosed brackets/braces detected.")
          
          if (writtenObjectsCount == 0) 
              throw Error("Warning: No valid JSON objects were parsed from the source file.")

          ; Close the stream to release the file lock
          outFile.Close()
          outFile := 0

          ; Guard 5: Replace target destination file atomically
          FileMove(tempFile, secondFile, true)
          
          
          return true
      } catch Error as err {
          OutputDebug("JsonToJsonl Failed: " . err.Message)
          
          ; Close temporary file stream if still open
          if (IsObject(outFile)) 
              outFile.Close()
          
          ; Clean up temporary file on failure
          if FileExist(tempFile) 
              try FileDelete(tempFile)
          
          
          return false
      }
  }

  /**
   * Read from a .jsonL file to copy and create to a new .json file. i.e. Convert.
   * @param firstFile string Convert from this .jsonL file
   * @param secondFile string Convert to this .json file
   * @param indent string Indentation for the output file
   * @returns bool True for successful conversion, False for failure
   */
  static JsonlToJson(firstFile := "jsonLFile.jsonl", secondFile := "jsonFile.json", indent := "  ") {
      ; Guard 1: Verify input file exists
      if !FileExist(firstFile) {
          OutputDebug("Error: Input file does not exist -> " . firstFile)
          return false
      }

      tempFile := secondFile . ".tmp"

      ; Clean up lingering temporary files
      if FileExist(tempFile) 
        try FileDelete(tempFile)
      
      outFile := 0

      try {
          ; Guard 2: Open output stream
          outFile := FileOpen(tempFile, "w", "UTF-8")
          if !IsObject(outFile) {
              OutputDebug("Error: Failed to create temporary file -> " . tempFile)
              return false
          }

          ; Start the root JSON array
          outFile.WriteLine("[")

          isFirstLine := true
          parsedCount := 0

          Loop Read, firstFile
          {
              line := Trim(A_LoopReadLine)

              ; Skip blank lines
              if (line == "")
                  continue

              ; Guard 3: Validate and load the JSON string
              try {
                  jsonObject := JSON.Load(line)
                  
                  ; Pretty-print the single object (using cJSON's indent parameter)
                  prettyBlock := JSON.Dump(jsonObject, indent)
              } catch Error as err {
                  OutputDebug("JSON Parsing Error on line:`n" . line . "`n`nError: " . err.Message)
                  throw err
              }

              ; Indent every line of the pretty block so it aligns inside the root array
              indentedBlock := ""
              Loop Parse, prettyBlock, "`n", "`r"
              {
                  if (A_LoopField != "")
                      indentedBlock .= indent . A_LoopField . "`n"
              }
              ; Remove the trailing newline for comma formatting
              indentedBlock := RTrim(indentedBlock, "`r`n")

              ; Prepend comma to all items except the first one
              if (!isFirstLine) 
                outFile.WriteLine(",")
              else 
                isFirstLine := false
              
              outFile.Write(indentedBlock)
              parsedCount++
          }

          ; Close the root array on a new line
          if (parsedCount > 0) 
              outFile.WriteLine()
          
          outFile.WriteLine("]")

          ; Guard 4: Validate that at least one JSON line was processed
          if (parsedCount == 0) 
              throw Error("Warning: No valid JSON lines found in the source file.")

          outFile.Close()
          outFile := 0

          ; Guard 5: Replace target destination file atomically
          FileMove(tempFile, secondFile, true)

          
          return true
      } catch Error as err {
          OutputDebug("JsonlToJson Failed: " . err.Message)

          if (IsObject(outFile)) 
            outFile.Close()

          if FileExist(tempFile) 
           try FileDelete(tempFile)
          

          return false
      }
  }

}