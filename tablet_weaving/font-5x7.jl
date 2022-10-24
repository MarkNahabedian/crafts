# From:
# http://scruss.com/wordpress/wp-content/uploads/2017/03/IBM029-Field-Eng-Maint-Man-p65-code-key.jpg

FONT_5x7 = Dict{AbstractChar, Array{UInt8, 2}}()

function defchar(char::AbstractChar, pattern::String)
    a = zeros(UInt8, 7, 5)
    for (row, bits) in enumerate(split(pattern, '\n'))
        if length(bits) == 0
            break
        end
        for (col, c) in enumerate(bits)
            if c != ' '
                a[row, col] = 1
            end
        end
    end
    global FONT_5x7[char] = a
end

defchar('A', """
  *  
 * * 
*   *
*   *
*****
*   *
*   *
""")

defchar('B', """
**** 
 *  *
 *  *
 *** 
 *  *
 *  *
**** 
""")

defchar('C', """
 *** 
*   *
*    
*    
*   *
 *** 
""")

defchar('D', """
**** 
 *  *
 *  *
 *  *
 *  *
 *  *
**** 
""")

defchar('E', """
*****
*    
*    
***  
*    
*    
*****
""")

defchar('F', """
*****
*    
*    
***  
*    
*    
*    
""")

defchar('G', """
 ****
*    
*    
*  **
*   *
*   *
 ****
""")

defchar('H', """
*   *
*   *
*   *
*****
*   *
*   *
*   *
""")

defchar('I', """
 *** 
  *  
  *  
  *  
  *  
  *  
 *** 
""")

defchar('J', """
    *
    *
    *
    *
    *
*   *
 *** 
""")

defchar('K', """
*   *
*  * 
* *  
**   
* *  
*  * 
*   *
""")

defchar('L', """
*    
*    
*    
*    
*    
*    
*****
""")

defchar('M', """
*   *
** **
* * *
* * *
*   *
*   *
*   *
""")

defchar('N', """
*   *
**  *
* * *
*  **
*   *
*   *
*   *
""")

defchar('O', """
*****
*   *
*   *
*   *
*   *
*   *
*****
""")

defchar('P', """
**** 
*   *
*   *
**** 
*    
*    
*    
""")

defchar('Q', """
 *** 
*   *
*   *
*   *
* * *
*  * 
 ** *
""")

defchar('R', """
**** 
*   *
*   *
**** 
* *  
*  * 
*   *
""")

defchar('S', """
 *** 
*   *
 *   
  *  
   * 
*   *
 *** 
""")

defchar('T', """
*****
  *  
  *  
  *  
  *  
  *  
  *  
""")

defchar('U', """
*   *
*   *
*   *
*   *
*   *
*   *
 ***
""")

defchar('V', """
*   *
*   *
*   *
 * * 
 * * 
  *  
  *  
""")

defchar('W', """
*   *
*   *
*   *
*   *
* * *
** **
*   *
""")

defchar('X', """
*   *
*   *
 * * 
  *  
 * * 
*   *
*   *
""")

defchar('Y', """
*   *
*   *
 * * 
  *  
  *  
  *  
  *  
""")

defchar('Z', """
*****
    *
   * 
  *  
 *   
*****
""")


defchar('0', """
  ** 
 *  *
 *  *
 *  *
 *  *
 *  *
  ** 
""")

defchar('1', """
  *  
 **  
  *  
  *  
  *  
  *  
 *** 
""")

defchar('2', """
 *** 
*   *
    *
 *** 
 *   
 *   
*****
""")

defchar('3', """
 888 
8   8
    8
  88 
    8
8   8
 888 
""")

defchar('4', """
   8 
  88 
 8 8 
8  8 
88888
   8 
   8 
""")

defchar('5', """
88888
8    
8888 
    8
    8
8   8
 888 
""")

defchar('6', """
  88 
 8   
8    
8888 
8   8
8   8
 888 
""")

defchar('7', """
88888
    8
   8 
  8  
 8   
 8   
 8   
""")

defchar('8', """
 888 
8   8
8   8
 888 
8   8
8   8
 888 
""")

defchar('9', """
 888 
8   8
8   8
 888 
    8
    8
 888 
""")


defchar('&', """
 *   
* *  
* *  
 *   
* * *
*  * 
 ** *
""")

defchar('-', """
     
     
     
     
*****
     
     
""")

defchar('/', """
     
    *
   * 
  *  
 *   
*    
     
""")

defchar('+', """
     
  *  
  *  
*****
  *  
  *  
""")

defchar('.', """
     
     
     
     
     
 **  
 **  
""")

defchar('<', """
    * 
   * 
  *  
 *   
  *  
   * 
    *
""")

defchar('>', """
*    
 *   
  *  
   *  
  *  
 *   
*    
""")

defchar('_', """
     
     
     
     
     
     
*****
""")

defchar(';', """
 88  
 88  
     
 88  
 88  
  8  
 8   
""")

defchar('!', """
   8 
   8 
   8 
   8 
   8 
     
   8 

""")

defchar(' ', """
     
     
     
     
     
     
    
""")

defchar('(', """
   * 
  *  
 *   
 *   
 *   
  *  
   * 
""")

defchar(')', """
 *   
  *  
   * 
   * 
   * 
  *  
 *   
""")

defchar('=', """
     
     
*****
     
*****
     
     
""")

defchar('\'', """ **  
 **  
 **       
     
     
     
     

""")

defchar('"', """ **  
 * * 
 * *      
     
     
     
     

""")

defchar(':', """
     
 88  
 88  
     
 88  
 66  
     
""")

defchar('#', """
 8 8 
 8 8 
88 88
     
88 88
 8 8 
 8 8 
""")

defchar(',', """
     
     
     
 88  
 88  
 8   
 8   
""")

defchar('$', """
  8  
 8888
8    
 888 
    8
8888 
  8  
""")

defchar('?', """
 888 
8  8 
   8 
  8  
  8  
     
  8  
""")

defchar('@', """
 888 
8   8
    8
 88 8
8 8 8
8 8 8
 8888
""")

defchar('%', """
88  8
88  8
   8 
  8  
 8   
8  88
8  88
""")

defchar('*', """
8 8 8
 888 
88888
 888 
8 8 8
""")

defchar('|', """
     
  8  
  8  
  8  
  8  
  8  
     
""")

defchar('¢', """
  8  
 888 
8    
8    
8    
 888 
  8  
""")

defchar('¬', """
     
     
     
     
88888
    8
    8
""")

