extern crate ndarray;

use num::complex::Complex;
use ndarray::linalg::kron;
use std::time::{Instant};

pub mod lib {
    pub mod gates;
    pub mod qubit;
}

use lib::qubit::{Qubit, kron1d};
use lib::gates::Gates;

fn main() {

    // Quantum teleporation Protocole
    // Splątane qubity Alicji i Boba
    let now = Instant::now();
    let mut x = Qubit::zero();
    let y = Qubit::zero();
    
    println!("Frist qubit in rust: {}" , x.to_string());

    x = x * Qubit::hadamard();

    println!("Second qubit in rust: {}" , x.to_string());

    let mut xy = kron1d(&x.to_vector(), &y.to_vector());
    // let mut xy = kron(&x.to_vector(), &y.to_vector());

    println!("Third qubit in rust: {}" , xy);
    xy = xy.dot(&Qubit::cnot());
    println!("Splątany: {}", xy);


    // Qubit do teleportownia
    let psi = Qubit::random();
    // let psi = Qubit::one();
    println!("Qubit po stronie Alicji {}", psi.to_string());

    // Pierwszy krok 
    let first = kron1d(&psi.to_vector(), &xy);
    println!("pierwszy = {}", first);

    // Drugi krok
    let cnot = kron(&Qubit::cnot(), &Qubit::identity());
    let second = first.dot(&cnot);
    println!("drugi = {}", second);

    // Trzeci krok 
    let mut hadamard = kron(&Qubit::hadamard(), &Qubit::identity());
    hadamard = kron(&hadamard, &Qubit::identity());
    let third = second.dot(&hadamard);
    println!("trzeci = {}", third);

    // Pomiar
    let m01 = kron(&Qubit::m0(), &Qubit::m1());
    let m010 = kron(&m01, &Qubit::identity());
    let mesure = third.dot(&m010);
    println!("pomiar = {}", mesure);

    let alpha = mesure[2] * Complex::new(2., 0.);
    let beta = mesure[3] * Complex::new(2., 0.);

    // Qubit po teleportacji
    let mut psi_after = Qubit::new(&alpha, &beta);
    psi_after = psi_after * Qubit::paulix();
    println!("Qubit po stronie Boba");
    println!("psi after = {}", psi_after.to_string());
    println!("Ukończono w czasie: {}", now.elapsed().as_millis());


}
