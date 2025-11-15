import java.io.FileInputStream
import java.util.Properties

// 1. Definição do caminho do arquivo keystore.properties
// O arquivo de build está em 'android/app/'. O arquivo 'key.properties' está em 'android/'.
val propertiesFileCorrect = file("../key.properties")

// 2. Carrega as propriedades, incluindo tratamento de erro.
val keystoreProperties = Properties().apply {
    if (propertiesFileCorrect.exists()) { 
        try {
            load(FileInputStream(propertiesFileCorrect))
            println("Key properties carregado com sucesso.")
        } catch (e: Exception) {
            throw GradleException("Falha ao carregar key.properties: ${e.message}")
        }
    } else {
        throw GradleException("O arquivo key.properties NÃO foi encontrado em ${propertiesFileCorrect.absolutePath}. Verifique o caminho.")
    }
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.vendocerto.automacao"
    
    // ATUALIZADO: Elevando o compileSdk para 36 para atender aos requisitos do Android 15.
    compileSdk = project.properties["flutter.compileSdkVersion"]?.toString()?.toInt() ?: 36
    
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.vendocerto.automacao"
        minSdk = flutter.minSdkVersion
        
        // CORREÇÃO CRÍTICA: TARGET SDK MÍNIMO EXIGIDO PELO GOOGLE PLAY (API 35)
        targetSdk = 35 
        
        // CORREÇÃO CRÍTICA: INCREMENTADO PARA 2 para resolver o erro "código de versão 1 já foi usado"
        versionCode = 19
        versionName = "1.0.0"
    }

    signingConfigs {
        create("release") {
            // 3. Garantindo o Caminho do Keystore:
            val storeFileName = keystoreProperties.getProperty("storeFile")
            
            if (storeFileName.isNullOrEmpty()) {
                throw GradleException("Propriedade 'storeFile' ausente ou vazia em key.properties.")
            }
            
            // CORREÇÃO CRÍTICA DO CAMINHO:
            storeFile = file("../$storeFileName")

            // 4. Forçando as outras propriedades
            keyAlias = keystoreProperties.getProperty("keyAlias")!!
            keyPassword = keystoreProperties.getProperty("keyPassword")!!
            storePassword = keystoreProperties.getProperty("storePassword")!!
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true 
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}