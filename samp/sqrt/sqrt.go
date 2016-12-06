package main

import "os"
import "fmt"
import "strconv"
import "log"
import "math"

func main() {

  if (len (os.Args) < 2 ) {
    fmt.Println("please provide an argument for finding the square root")
    os.Exit(1)
  }

  fval, err := strconv.ParseFloat(os.Args[1],64)

  if  err != nil  { log.Fatal(err) }

  if fval < 0.0 {
    fmt.Println("please provide a positive number")
    os.Exit(1)
  }

  fsqrtval := square_root(fval)
  fmt.Printf("iterative square root of %0.8f is %0.8f\n",fval,fsqrtval)
  
  fsqrtval_recurse := square_root_r(fval,0,0)
  fmt.Printf("recursive square root of %0.8f is %0.8f\n",fval,fsqrtval_recurse)

}

func square_root_r(val float64, hi float64, lo float64) (float64) {

  var MARGIN float64 = 0.000000001 
  if  hi <= 0.0 {  
    hi = val
    if val < 1 {
      hi = 1
    }
  }

  if  lo <= 0.0 {
    lo = 0
    if val >= 1 {
      lo = 1
    }
  }
 
  var guess float64 = (hi + lo) / 2
  var chk float64 = guess * guess
  if  math.Abs( chk - val ) <= MARGIN {
    return guess
  }
  if chk > val {
    hi = guess
  } else {
    lo = guess
  }
  
  return square_root_r(val,hi,lo)

}


func square_root(val float64) (float64) {

  var hi, lo float64 = val, 0.0
  var MARGIN float64 = 0.000000001 
  var guess,chk float64 = -1.0, -1.0

  if val >= 1 { 
    lo = 1.0 
  } else { 
    hi = 1.0 
  } 


  for {
    guess = (hi + lo) / 2
    chk = guess * guess
    if  math.Abs( chk - val ) <= MARGIN {
      return guess;
    }
    if  chk > val {
      hi = guess
    } else {
      lo = guess
    }
  }  
  return -1.0
}

