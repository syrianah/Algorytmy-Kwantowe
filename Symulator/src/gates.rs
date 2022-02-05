// #[macro_use]
extern crate ndarray;

use ndarray::prelude::*;
use num::Complex;
use ndarray::Array2;

pub fn hadamard() -> Array2<Complex<f64>> {
    return array![[Complex::new(1./(2. as f64).sqrt(), 0.), Complex::new(1./(2. as f64).sqrt(), 0.)],
                  [Complex::new(1./(2. as f64).sqrt(), 0.), Complex::new(-1./(2. as f64).sqrt(), 0.)]];
}

pub fn paulix() -> Array2<Complex<f64>> {
    return array![[Complex::new(0., 0.), Complex::new(1., 0.)],
                  [Complex::new(1., 0.), Complex::new(0., 0.)]];
}

pub fn cnot() -> Array2<Complex<f64>> {
    return array![[Complex::new(1., 0.), Complex::new(0., 0.), Complex::new(0., 0.), Complex::new(0., 0.)],
                  [Complex::new(0., 0.), Complex::new(1., 0.), Complex::new(0., 0.), Complex::new(0., 0.)],
                  [Complex::new(0., 0.), Complex::new(0., 0.), Complex::new(0., 0.), Complex::new(1., 0.)],
                  [Complex::new(0., 0.), Complex::new(0., 0.), Complex::new(1., 0.), Complex::new(0., 0.)]]
}

pub fn identity() -> Array2<Complex<f64>> {
    return array![[Complex::new(1., 0.), Complex::new(0., 0.)],
                  [Complex::new(0., 0.), Complex::new(1., 0.)]];
}

pub fn m0() -> Array2<Complex<f64>> {
    return array![[Complex::new(1., 0.), Complex::new(0., 0.)],
                  [Complex::new(0., 0.), Complex::new(0., 0.)]];
}

pub fn m1() -> Array2<Complex<f64>> {
    return array![[Complex::new(0., 0.), Complex::new(0., 0.)],
                  [Complex::new(0., 0.), Complex::new(1., 0.)]];
}