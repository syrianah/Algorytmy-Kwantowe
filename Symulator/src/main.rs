extern crate ndarray;

use ndarray::prelude::*;

mod qubit;
mod gates;
use num::complex::Complex;
use ndarray::arr2;
use ndarray::linalg::kron;
use qubit::Qubit;
// use qubit::kron;
use qubit::kron1d;
use gates::hadamard;
use gates::cnot;
use gates::identity;
use gates::m0;
use gates::m1;
use gates::paulix;
use std::time::{Instant};
// use std::vec;

fn main() {
    // let complex_integer = Complex::new(10, 20);
    // let complex_float = Complex::new(10.1, 20.1);

    // println!("Test: {}", f64::powf(2.0, 3.0));

    // let cgs = [[1, 0, 0], [0, 1, 0], [0, 0, 1]];
    // println!("Dupa: {}", cgs[1][2]);

    // // let mut vec1 = vec![1, 2, 3];

    // let cgs2 = vec![vec![1, 0, 0], vec![0, 1, 0], vec![0, 0, 1]];
    // println!("Dupa: {}", cgs2[1][2]);

    // let a = arr2(&[[1, 2, 3],
    //     [4, 5, 6]]);

    // let b = arr2(&[[6, 5, 4],
    //         [3, 2, 1]]);

    // let sum = &a + &b;

    // println!("{}", a);
    // println!("+");
    // println!("{}", b);
    // println!("=");
    // println!("{}", sum);
    // // println!("Dupa: {}", a[1][2]);

    // let xd = Complex::new(1./(2. as f64).sqrt(), 0.);
    // println!("{}", xd);


    // let xd2 = array![Complex::new(1./(2. as f64).sqrt(), 0.), Complex::new(0., 0.)]
    

    // Quantum teleporation Protocole
    // Splątane qubity Alicji i Boba
    let now = Instant::now();
    let mut x = Qubit::zero();
    let y = Qubit::zero();
    
    println!("Frist qubit in rust: {}" , x.to_string());

    x = x.mul(hadamard());

    println!("Second qubit in rust: {}" , x.to_string());

    let mut xy = kron1d(&x.to_vector(), &y.to_vector());
    // let mut xy = kron(&x.to_vector(), &y.to_vector());

    println!("Third qubit in rust: {}" , xy);
    xy = xy.dot(&cnot());
    println!("Splątany: {}", xy);


    // Qubit do teleportownia
    let psi = Qubit::random();
    // let psi = Qubit::one();
    println!("Qubit po stronie Alicji {}", psi.to_string());

    // Pierwszy krok 
    let first = kron1d(&psi.to_vector(), &xy);
    println!("pierwszy = {}", first);

    // Drugi krok
    let cnot = kron(&cnot(), &identity());
    let second = first.dot(&cnot);
    println!("drugi = {}", second);

    // Trzeci krok 
    let mut hadamard = kron(&hadamard(), &identity());
    hadamard = kron(&hadamard, &identity());
    let third = second.dot(&hadamard);
    println!("trzeci = {}", third);

    // Pomiar
    let m01 = kron(&m0(), &m1());
    let m010 = kron(&m01, &identity());
    let mesure = third.dot(&m010);
    println!("pomiar = {}", mesure);

    let alpha = mesure[2] * Complex::new(2., 0.);
    let beta = mesure[3] * Complex::new(2., 0.);

    // Qubit po teleportacji
    let mut psi_after = Qubit::new(&alpha, &beta);
    psi_after = psi_after.mul(paulix());
    println!("Qubit po stronie Boba");
    println!("psi after = {}", psi_after.to_string());
    println!("Ukończono w czasie: {}", now.elapsed().as_millis());


}
