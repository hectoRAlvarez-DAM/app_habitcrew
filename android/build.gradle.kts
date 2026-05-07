allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Eliminamos el bloque complejo de 'newBuildDir' que está fallando
// y dejamos que Flutter use sus rutas por defecto.

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}