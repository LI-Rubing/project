#!/bin/bash
echo "Compilation..."
javac -cp "lib/*" src/improved_serveurZv2.java
echo "Exécution..."
java -cp "src:lib/*" improved_serveurZv2
