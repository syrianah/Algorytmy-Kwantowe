use num::complex::Complex;
mod qubit;

fn main() {
    let complex_integer = Complex::new(10, 20);
    let complex_float = Complex::new(10.1, 20.1);

    println!("Test: {}", f64::powf(2.0, 3.0));


    // let x = qubit::Qubit::new(&Complex::new(1.0, 0.0), &Complex::new(0.0, 0.0));
    let x = qubit::Qubit::zero();

    println!("Frist qubit in rust: |Ψ> = {}|0> + {}|1>" , x.alfa(), x.beta());
    println!("Frist qubit in rust: {}" , x.to_string());

    println!("Complex integer: {}", complex_integer);
    println!("Complex float: {}", complex_float);
}
