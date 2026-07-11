allprojects {
    repositories {
        google()
        mavenCentral()
        flatDir {
            dirs(file("${project.rootDir}/../../unityLibrary/libs"))
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "org.jetbrains.kotlin") {
                useVersion("2.1.0")
            }
        }
    }
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.getByName("android")
            
            if (android is com.android.build.gradle.BaseExtension) {
                // Fix for AGP 8.0+ Namespace requirement
                // We set the namespace to match the package name expected by the library
                if (android.namespace == null) {
                    val packageName = when (project.name) {
                        "flutter_jailbreak_detection" -> "appmire.be.flutterjailbreakdetection"
                        "flutter_secure_storage" -> "com.it_st.flutter_secure_storage"
                        "path_provider_android" -> "io.flutter.plugins.pathprovider"
                        "shared_preferences_android" -> "io.flutter.plugins.sharedpreferences"
                        else -> "com.meowtrack.${project.name.replace("-", "_")}"
                    }
                    android.namespace = packageName
                }

                android.compileSdkVersion(35)
                
                android.compileOptions.sourceCompatibility = JavaVersion.VERSION_17
                android.compileOptions.targetCompatibility = JavaVersion.VERSION_17
            }

            tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                kotlinOptions {
                    jvmTarget = "17"
                    // INI KUNCI DIA: Benarkan metadata 2.1 tapi guna logik 1.9 untuk elak crash
                    languageVersion = "1.9"
                    apiVersion = "1.9"
                    freeCompilerArgs = freeCompilerArgs + listOf("-Xskip-metadata-version-check")
                }
            }
        }
    }
}

subprojects {
    if (project.name != "app") {
        project.evaluationDependsOn(":app")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
