// #[macro_use]
extern crate ndarray;

use ndarray::prelude::*;
use num::complex::Complex;
use std::ops::Mul;
use rand::Rng;

pub struct Qubit {
    alfa: Complex<f64>,
    beta: Complex<f64>,
}

impl Qubit {
    // Qubit constructor - check is it qubit
    pub fn new(a: &Complex<f64>, b: &Complex<f64>) -> Qubit {
        let check = f64::powf(a.norm_sqr(), 2.0) + f64::powf(b.norm_sqr(), 2.0);
        if 0.999999998 <= check || check <= 1.00000001{
            Qubit {
                alfa: *a,
                beta: *b
            }
        }
        else {
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
        return format!("|Ψ> = {}|0> + {}|1>", self.alfa, self.beta)
    }

    // Get qubit in vector representation
    pub fn to_vector(&self) ->  Array<Complex<f64>, Dim<[usize; 1]>> {
        return array![self.alfa, self.beta];
    }

    // Get random qubit, not working every time (same as in python xd)
    pub fn random() -> Qubit {
        let mut rng = rand::thread_rng();
        let mut a = rng.gen_range(-1.0..1.0);
        let mut b = rng.gen_range(-1.0..1.0);
        while f64::powf(a, 2.) > 1. - f64::powf(b, 2.){
            a = rng.gen_range(-1.0..1.0);
            b = rng.gen_range(-1.0..1.0);     
        }

        let alpha = Complex::new(a, b);
        let abs_beta = (1. - f64::powf(alpha.norm_sqr(), 2.)  as f64).sqrt();
        let mut c = rng.gen_range(-1.0..1.0);
        let mut d = f64::powf(abs_beta, 2.) - c;
        while c > 1. - f64::powf(a, 2.) {
            c = rng.gen_range(-1.0..1.0);
        }
        d = f64::powf(f64::powf(abs_beta, 2.) - f64::powf(c, 2.), 0.5);
        let beta = Complex::new(c, d);
        return Qubit::new(&alpha, &beta);
    }
    

}

 // Get qubit operation with 2d gate
impl Mul<Array2<Complex<f64>>> for Qubit {
    type Output = Self;

    fn mul(self, gate: Array2<Complex<f64>>) -> Self::Output  {
        let a = gate[[0, 0]] * self.alfa + gate[[0, 1]] * self.beta;
        let b = gate[[1, 0]] * self.alfa + gate[[1, 1]] * self.beta;
        return Qubit::new(&a, &b);
    }
}

// Iloczyn tensorowy Kronecera dwóch wektorów
pub fn kron1d(a: &Array<Complex<f64>, Dim<[usize; 1]>>, b: &Array<Complex<f64>, Dim<[usize; 1]>>) -> Array<Complex<f64>, Dim<[usize; 1]>> {
    let dimout = a.len() * b.len();
    let mut out = Array::zeros(dimout);
    let mut id = 0;
    for i in 0..=a.len()-1{
        for j in 0..=b.len()-1{
             out[id] = a[i] * b[j];
             id+=1;
        }   
    }
    return out;
}
