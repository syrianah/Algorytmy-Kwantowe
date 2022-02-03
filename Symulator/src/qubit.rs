// use std::f64::consts::PI;
use num::complex::Complex;
use std::ops::Mul;
use ndarray::arr2;
use ndarray::Array;

pub struct Qubit {
    alfa: Complex<f64>,
    beta: Complex<f64>,
}

impl Qubit {
    // Qubit constructor - check is it qubit
    pub fn new(a: &Complex<f64>, b: &Complex<f64>) -> Qubit {
        let check = f64::powf(a.norm_sqr(), 2.0) + f64::powf(b.norm_sqr(), 2.0);
        println!("Check: {}", check);
        if 0.999999998 <= check && check <= 1.00000001{
            Qubit {
                alfa: *a,
                beta: *b
            }
        }
        else {
            // maybe add error handle?
            panic!("Cannot create qubit");
        }

    }

    // Get alfa state
    pub fn alfa(&self) -> Complex<f64> {
        self.alfa
    }

    // Get beta state
    pub fn beta(&self) -> Complex<f64> {
        self.beta
    }

    // Get |0> qubit
    pub fn zero() -> Qubit {
        self::Qubit::new(&Complex::new(1.0, 0.0), &Complex::new(0.0, 0.0))
    }

    // Get |1> qubit
    pub fn one() -> Qubit {
        self::Qubit::new(&Complex::new(0.0, 0.0), &Complex::new(1.0, 0.0))
    }

    // Get qubit in string representation
    pub fn to_string(&self) -> String {
        format!("|Ψ> = {}|0> + {}|1>", self.alfa, self.beta)
    }

}
//TODO
// change to vector!

// impl Mul for Qubit {
//     type Output = Self;

//     fn mul(&self, gate: Array<Array<Complex<f64>, i32>, i32>){
//         let alpha = gate[0, 0]
//     }
// }