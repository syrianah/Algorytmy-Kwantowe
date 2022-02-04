// use std::f64::consts::PI;
// #[macro_use]
extern crate ndarray;
// extern crate rand;

use ndarray::prelude::*;
use num::complex::Complex;
use std::ops::Mul;
use ndarray::arr2;
use ndarray::Array2;
use ndarray::ArrayBase;
use ndarray::OwnedRepr;
use rand::Rng;

pub struct Qubit {
    alfa: Complex<f64>,
    beta: Complex<f64>,
}

impl Qubit {
    // Qubit constructor - check is it qubit
    pub fn new(a: &Complex<f64>, b: &Complex<f64>) -> Qubit {
        let check = f64::powf(a.norm_sqr(), 2.0) + f64::powf(b.norm_sqr(), 2.0);
        println!("Check: {}", check);
        if 0.999999998 <= check || check <= 1.00000001{
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
        return format!("|Ψ> = {}|0> + {}|1>", self.alfa, self.beta)
    }

    // pub fn to_vector(&self) ->  ArrayBase<OwnedRepr<Complex<f64>>, Dim<[usize; 1]>> {
    //     return array![self.alfa, self.beta];
    // }
    pub fn to_vector(&self) ->  Array<Complex<f64>, Dim<[usize; 1]>> {
        return array![self.alfa, self.beta];
    }

    // Get qubit operation with 2d gate
    pub fn mul(self: Qubit, gate: Array2<Complex<f64>>) -> Qubit{
        let a = gate[[0, 0]] * self.alfa + gate[[0, 1]] * self.beta;
        let b = gate[[1, 0]] * self.alfa + gate[[1, 1]] * self.beta;
        return Qubit::new(&a, &b);
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

pub fn kron1d(a: &Array<Complex<f64>, Dim<[usize; 1]>>, b: &Array<Complex<f64>, Dim<[usize; 1]>>) -> Array<Complex<f64>, Dim<[usize; 1]>> {
    return array![a[0]*b[0], a[0]*b[1], a[1]*b[0], a[1]*b[1]]
}

pub fn kron(a: &Array2<Complex<f64>>, b: &Array2<Complex<f64>>) -> Array2<Complex<f64>> {
    let dima = a.shape()[0];
    let dimb = b.shape()[0];
    let dimout = dima * dimb;
    let mut out = Array2::zeros((dimout, dimout));
    for (mut chunk, elem) in out.exact_chunks_mut((dimb, dimb)).into_iter().zip(a.iter()) {
        chunk.assign(&(*elem * b));
    }
    out
}

// pub fn mulGate(qubit: Qubit, gate: [[Complex<f64>; 2]; 2]){
//     let alpha = gate[0][0] * qubit.alfa() + gate[0][1] * qubit.beta();
//     let beta = gate[0][0] * qubit.alfa() + gate[1][1] * qubit.beta();
//     Qubit::new(&alpha, &beta);
// }

//TODO
// change to vector!

// impl Mul for Qubit {
//     type Output = Self;

//     fn mul(self: Qubit, gate: [[Complex<f64>; 2]; 2]){
//         let alpha = gate[0][0] * self.alfa + gate[0][1] * self.beta;
//         let beta = gate[0][0] * self.alfa + gate[1][1] * self.beta;
//         Qubit::new(&alpha, &beta);
//     }
// }