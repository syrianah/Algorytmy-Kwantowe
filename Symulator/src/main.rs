extern crate ndarray;

use ndarray::prelude::*;

mod qubit;
mod gates;
use num::complex::Complex;
use ndarray::arr2;
use qubit::Qubit;
use qubit::kron;
use qubit::kron1d;
use gates::hadamard;
use gates::cnot;
// use std::vec;

fn main() {
    let complex_integer = Complex::new(10, 20);
    let complex_float = Complex::new(10.1, 20.1);

    println!("Test: {}", f64::powf(2.0, 3.0));

    let cgs = [[1, 0, 0], [0, 1, 0], [0, 0, 1]];
    println!("Dupa: {}", cgs[1][2]);

    // let mut vec1 = vec![1, 2, 3];

    let cgs2 = vec![vec![1, 0, 0], vec![0, 1, 0], vec![0, 0, 1]];
    println!("Dupa: {}", cgs2[1][2]);

    let a = arr2(&[[1, 2, 3],
        [4, 5, 6]]);

    let b = arr2(&[[6, 5, 4],
            [3, 2, 1]]);

    let sum = &a + &b;

    println!("{}", a);
    println!("+");
    println!("{}", b);
    println!("=");
    println!("{}", sum);
    // println!("Dupa: {}", a[1][2]);

    let xd = Complex::new(1./(2. as f64).sqrt(), 0.);
    println!("{}", xd);


    // let xd2 = array![Complex::new(1./(2. as f64).sqrt(), 0.), Complex::new(0., 0.)]
    

    //Quantum teleporation Protocole
    // let x = qubit::Qubit::new(&Complex::new(1.0, 0.0), &Complex::new(0.0, 0.0));
    let mut x = Qubit::zero();
    let y = Qubit::zero();
    
    println!("Frist qubit in rust: |Ψ> = {}|0> + {}|1>" , x.alfa(), x.beta());
    println!("Frist qubit in rust: {}" , x.to_string());

    x = x.mul(hadamard());

    println!("Second qubit in rust: |Ψ> = {}|0> + {}|1>" , x.alfa(), x.beta());
    println!("Second qubit in rust: {}" , x.to_string());

    let mut xy = kron1d(&x.to_vector(), &y.to_vector());

    println!("Third qubit in rust: {}" , xy);
    xy = xy.dot(&cnot());
    println!("Splątany: {}", xy);


    //Qubit do teleportownia
    let psi = Qubit::random();
    println!("Qubit po stronie Alicji {}", psi.to_string());
}
