// #[macro_use]
extern crate ndarray;

use ndarray::prelude::*;
use num::Complex;
use ndarray::Array2;
use super::qubit::{Qubit};


pub trait Gates {
    fn hadamard() -> Array2<Complex<f64>>;
    fn paulix() -> Array2<Complex<f64>>;
    fn cnot() -> Array2<Complex<f64>>;
    fn identity() -> Array2<Complex<f64>>;
    fn m0() -> Array2<Complex<f64>>;
    fn m1() -> Array2<Complex<f64>>;

}

impl Gates for Qubit {
    fn hadamard() -> Array2<Complex<f64>> {
        return array![[Complex::new(1./(2. as f64).sqrt(), 0.), Complex::new(1./(2. as f64).sqrt(), 0.)],
                      [Complex::new(1./(2. as f64).sqrt(), 0.), Complex::new(-1./(2. as f64).sqrt(), 0.)]];
    }
    
    fn paulix() -> Array2<Complex<f64>> {
        return array![[Complex::new(0., 0.), Complex::new(1., 0.)],
                      [Complex::new(1., 0.), Complex::new(0., 0.)]];
    }
    
    fn cnot() -> Array2<Complex<f64>> {
        return array![[Complex::new(1., 0.), Complex::new(0., 0.), Complex::new(0., 0.), Complex::new(0., 0.)],
                      [Complex::new(0., 0.), Complex::new(1., 0.), Complex::new(0., 0.), Complex::new(0., 0.)],
                      [Complex::new(0., 0.), Complex::new(0., 0.), Complex::new(0., 0.), Complex::new(1., 0.)],
                      [Complex::new(0., 0.), Complex::new(0., 0.), Complex::new(1., 0.), Complex::new(0., 0.)]]
    }
    
    fn identity() -> Array2<Complex<f64>> {
        return array![[Complex::new(1., 0.), Complex::new(0., 0.)],
                      [Complex::new(0., 0.), Complex::new(1., 0.)]];
    }
    
    fn m0() -> Array2<Complex<f64>> {
        return array![[Complex::new(1., 0.), Complex::new(0., 0.)],
                      [Complex::new(0., 0.), Complex::new(0., 0.)]];
    }
    
    fn m1() -> Array2<Complex<f64>> {
        return array![[Complex::new(0., 0.), Complex::new(0., 0.)],
                      [Complex::new(0., 0.), Complex::new(1., 0.)]];
    }
}

