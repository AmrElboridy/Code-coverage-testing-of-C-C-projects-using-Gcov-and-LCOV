/*
 * VCPU_RSU Jenkinsfile
 *
 * Input parameters:
 * PIP_PROMOTE = true/false, enables promotion feature to release artifacts
 * PIP_PROMOTE_BRANCH = "name-of-branch", promotion branch to release the git hash
 * PIP_PROMOTE_UNSTABLE = "false", promote unstable build
 *
 * Promotion output:
 * output.zip, don't rename this without approval from verification
 *
 * Before you check in this file, make sure you've done:
 *     f=Jenkinsfile ;
 *       # TABs to 4*Spaces
 *       perl -p -i -e "s/\t/    /g" ${f} ;         # IMPORTANT!
 *       # No Trailing Spaces (ymllint)
 *       perl -p -i -e "s/\s+\n/\n/g" ${f} ;
 *       # NL -> N (\r\n -> \n)
 *       dos2unix ${f} ;
 *     # Optional:
 *       yamllint ${f} ;
 */

@Library('mbient-pipeliner-depot@release-latest')
import com.daimler.pipeliner.Logger
import com.luxoft.pipelinerdepot.utils.ArtifactsArchiver
import com.luxoft.pipelinerdepot.stages.mbient.CommonStages

import groovy.io.FileType
import groovy.json.*
import java.nio.file.Path
import java.nio.file.Paths
import java.time.format.DateTimeFormatter
import java.time.Instant

if (scmCheck(verbose: true).scmValid) {
    scmBak = scm
}
execMergeRequestPreHook()

def getPropOrDefault( Closure closurePropName, Closure closureDefaultValue ) {
    try {
        return closurePropName()
    }
    catch( groovy.lang.MissingPropertyException e ) {
        return getPropOrDefault(closureDefaultValue, { null })
    }
}

def isJobStartedByTimer() {
    try {
        for ( buildCause in currentBuild.getBuildCauses() ) {
            if (buildCause != null) {
                if (buildCause.shortDescription.contains("Started by timer")) {
                    echo " Running on nighlty Job..."
                    return true
                }
                else {
                    echo " Current build is not started by timer !"
                }
            }
        }
    } catch(theError) {
        echo "Error getting build cause: ${theError}"
    }
    return false
}

Map<String, String> parseMergeRequest(String mergeRequest) {
    // Parses merge request text and maps values that are key=value
    Map metadata = [:]
    if (mergeRequest) {

        List<String> keyValuePairs = mergeRequest.split('\n')
        keyValuePairs = keyValuePairs.collect {it.trim()}

        for (line in keyValuePairs) {
            def keyValuePairMatcher = (line =~ /^(.*?)=(.*)$/)
            if (!keyValuePairMatcher || keyValuePairMatcher.size() < 1) {
                continue
            }
            final List<String> keyValuePairAsList = (ArrayList<String>) keyValuePairMatcher[0]
            final String rawKey = keyValuePairAsList[1]
            final String rawValue = keyValuePairAsList[2]
            if (rawKey && rawKey.trim()) {
                final String key = rawKey.trim().toLowerCase()
                final String value = rawValue.trim()
                metadata[key] = value
            }
        }
    }
    return metadata
}

def robocopy(String parametersString) {
    // robocopy uses non-zero exit code even on success, status below 3 is fine
    def status = bat returnStatus: true, script: "ROBOCOPY ${parametersString}"
    println "ROBOCOPY ${parametersString} returned ${status}"
    if (status < 0 || status > 3)
    {
        error("ROBOCOPY failed")
    }
}

def scmCheck(Map kwargs = [:]) {
    scm = getPropOrDefault({ scmBak }, { scm })
    if (kwargs.verbose == true) {
        println("scmCheck() checking SCM infos...")
        println("scm = "+scm?.dump())
    }
    Boolean scmValid
    Boolean infosFound
    Boolean isMerge
    String repoUrl
    if (scm == null || scm instanceof hudson.scm.NullSCM) { // Check if global variable scm is correctly initialized.
        scmValid = false
    } else {
        scmValid = true
    }
    if (env.gitlabActionType == null && !scmValid) { // Check if any SCM info available in environment or scm.
        infosFound = false
    } else {
        infosFound = true
    }
    if (env.gitlabActionType == 'MERGE' ||
        (scmValid && scm.branches.size() > 1)) { // Check if the build is based on a merge of two branches.
        isMerge = true
    } else {
        isMerge = false
    }
    if (scmValid) { // Get remote url of repository
        repoUrl = scm.userRemoteConfigs[0].getUrl()
    } else {
        repoUrl = env.gitlabSourceRepoURL
    }
    result = [
     scmValid: scmValid,
     infosFound: infosFound,
     isMerge: isMerge,
     repoUrl: repoUrl
    ]
    if (kwargs.verbose == true) {
        println("Result of scmCheck(): "+result.dump())
    }
    return result
}

def gitFullClone(String gitCacheDir, String repoUrl, String repoName, String cloneReference) {
    // Populate local cache to be used as a clone reference
    bat script: "if not exist ${gitCacheDir} (mkdir ${gitCacheDir})"
    bat script: "if not exist ${gitCacheDir}\\${repoName}\\.git (git lfs install)"
    bat script: "if not exist ${gitCacheDir}\\${repoName}\\.git (git clone ${repoUrl} ${gitCacheDir}\\${repoName})"
    bat script: "git -C ${gitCacheDir}\\${repoName} remote prune origin"
    bat script: "git -C ${gitCacheDir}\\${repoName} pull" // keep the reference repository up-to-date
    print "Full cloning..."
    scmCheckResult = scmCheck()
    if(scmCheckResult.scmValid){ // Use Git plugin of Jenkins to do checkout
        scmVars = checkout([ //do a full clone
         $class: 'GitSCM',
         branches: scm.branches,
         doGenerateSubmoduleConfigurations: scm.doGenerateSubmoduleConfigurations,
         extensions: scm.extensions + [
          [$class: 'CheckoutOption', timeout: 240] ,[$class: 'GitLFSPull'],
          [$class: 'CloneOption', reference: "${cloneReference}", timeout: 240]
         ],
         userRemoteConfigs: scm.userRemoteConfigs
        ])
    // Populate local cache to be used as a clone reference
    print "Fetching..."
        def fetchStatus = bat returnStatus: true, script: "git -C ${gitCacheDir}\\${repoName} fetch" // keep the reference repository up-to-date
    	if (fetchStatus != 0) 
    	{ // try remove origin refs and fetch again
        def origFolder = "${gitCacheDir}\\${repoName}\\.git\\refs\\remotes\\origin"
        bat script: "if exist \"${origFolder}\" (rmdir \"${origFolder}\" /s/q)"
        bat script: "git -C ${gitCacheDir}\\${repoName} fetch"
    	}
    print "Full cloning..."
    }
    else { // Falling back to git commands to do checkout.
        println("The global variable scm is not correctly initialized. Falling back to git commands to do checkout...")
        bat script: "git clone --reference ${cloneReference} ${repoUrl} ."
        bat script: "git checkout ${env.gitlabSourceBranch}"
        bat script: "git pull"
        if (scmCheckResult.isMerge) {
            def status = bat returnStatus: true, script: "git -c user.email=\"${env.gitlabUserEmail}\" -c user.name=\"${env.gitlabUserName}\" merge origin/${env.gitlabTargetBranch}"
            if (status != 0) {
                error("Automatic merge failed.")
            }
        }
        scmVars = [ // Imitate the return value of checkout().
         GIT_BRANCH: bat(returnStdout: true, script: "@git rev-parse --abbrev-ref HEAD"),
         GIT_COMMIT: bat(returnStdout: true, script: "@git rev-parse HEAD"),
         GIT_URL: bat(returnStdout: true, script: "@git config --get remote.origin.url")
        ]
    }
    println("scmVars = "+scmVars.dump())
    return scmVars
}

def gitShallowClone(String gitCacheDir, String repoUrl, String repoName, String cloneReference) {
    def gitBranchArray = []
    def refspecFetchString = ""
    def refspecMatcherArray = []
    def noTagsBoolean = true
    scm.branches.eachWithIndex{branchSpecifier,index-> // parse the branch specifiers
        refspecMatcherArray = sh(
         returnStdout: true,
         script: "git ls-remote ${repoUrl} ${branchSpecifier}|cut -f 2"
         ).trim().split("\\r\\n|\\n|\\r")
        if (refspecMatcherArray.length > 1){
            print "Found multiple branches with branch specifier '${branchSpecifier}':\n${refspecMatcherArray.join("\\r\\n")}"
            print "The first is taken: ${refspecMatcherArray[0]}"
            gitBranchArray.add(refspecMatcherArray[0].split("/")[2..-1].join("/"))
            refspecFetchString += "+${refspecMatcherArray[0]}:refs/remotes/origin/${gitBranchArray[-1]} "
        }else{
            if (refspecMatcherArray[0].length() == 0){
                print "No branch is found with branch specifier '${branchSpecifier}'."
                gitBranchArray.add(branchSpecifier.toString().split("/")[-1])
                print "The string after the last slash is taken as branch name: ${gitBranchArray[-1]}."
                refspecFetchString += "+refs/heads/${gitBranchArray[-1]}:refs/remotes/origin/${gitBranchArray[-1]} "
            }else{
                if (refspecMatcherArray[0].split("/")[1] == "tags"){
                    noTagsBoolean = false
                }
                gitBranchArray.add(refspecMatcherArray[0].split("/")[2..-1].join("/"))
                print "With branch specifier '${branchSpecifier}' the branch '${gitBranchArray[-1]}' is found."
                refspecFetchString += "+${refspecMatcherArray[0]}:refs/remotes/origin/${gitBranchArray[-1]} "
            }
        }
    }
    print "Shallow cloning with refspecs: ${refspecFetchString}"
    try{
        scmVars = checkout([ // do shallow clone
         $class: 'GitSCM',
         branches: scm.branches,
         doGenerateSubmoduleConfigurations: scm.doGenerateSubmoduleConfigurations,
         extensions: scm.extensions + [
          [$class: 'CheckoutOption', timeout: 240] ,[$class: 'GitLFSPull'],
          [$class: 'CloneOption', reference: "${cloneReference}", timeout: 240,
            noTags: noTagsBoolean, shallow: true, depth: 1, honorRefspec: true]
         ],
         userRemoteConfigs: [[url: scm.userRemoteConfigs[0].url, credentialsId: scm.userRemoteConfigs[0].credentialsId, refspec: refspecFetchString]]
        ])
    }catch(e){
        print "Shallow clone failed. Falling back to full clone..."
        scmVars = gitFullClone(gitCacheDir, repoUrl, repoName, cloneReference)
    }
    return scmVars
}

// **********\/*****Modul for enabling the optional stages*****\/**********
// Enabled optional stages by default
enabledOptionalStages = [
    'Run bat files for bootloader',
    'VCPU Bootloader Unit Test',
    'VCPU Bootloader Component Test',
    'VCPU Application Unit Test',
    'Run bat file for APP.DNL and BL.DNL file creation',
    'Generate Output',
    'Archive inside Jenkins'
]

//    'Enable GLIWA build',
//    'VCPU Bootloader Unit Test',
//    'VCPU Bootloader Component Test',
//    'Run bat file for VCPU component tests',
//    'Run bat file for APP.DNL and BL.DNL file creation',
//    'Generate Output',
//    'Archive'
//    'Archive inside Jenkins'

// Overloading the funtion stage() to catch the keyword argumentes
def stage(Map kwargs, String name, Closure block) {
    if (kwargs.optional == true) {
        print "Stage '${name}' is optional. Checking wether it is enabled..."
        if (enabledOptionalStages.contains(name)) {
            print "Stage '${name}' is enabled. Executing..."
            return stage(name, block)
        } else {
            print "Stage '${name}' is not enabled. Skipped."
            return
        }
    }
    return stage(name, block)
}

// Call this function to override the default list of enabled optional stages according to branch name or build type
def enableOptionalStages() {
    List integrationBranches = [
        'master_RSU',
        'integration_RSU'
    ]
    // For merge request builds
    if (scmCheck().isMerge) {
        // Default for merge request builds
        enabledOptionalStages = [
          'Run bat files for bootloader',
          'VCPU Bootloader Unit Test',
          'VCPU Bootloader Component Test',
          'VCPU Application Unit Test',
          'Run bat file for APP.DNL and BL.DNL file creation',
          'Generate Output',
          'Archive inside Jenkins'
        ]
        // From feature branches to integration_RSU
        if (!integrationBranches.contains(env.gitlabSourceBranch) &&
            env.gitlabTargetBranch == "integration_RSU") {
            enabledOptionalStages = [
                'Run bat files for bootloader',
                'VCPU Bootloader Unit Test',
                'VCPU Bootloader Component Test',
                'VCPU Application Unit Test',
                'Run bat file for APP.DNL and BL.DNL file creation',
                'Generate Output',
                'Archive inside Jenkins'
            ]
        }
        // From integration_RSU to master_RSU
        if (env.gitlabSourceBranch == "integration_RSU" &&
            env.gitlabTargetBranch == "master_RSU") {
            enabledOptionalStages = [
                'Run bat files for bootloader',
                'VCPU Bootloader Unit Test',
                'VCPU Bootloader Component Test',
                'VCPU Application Unit Test',
                'Run bat file for APP.DNL and BL.DNL file creation',
                'Generate Output',
                'Archive inside Jenkins'
            ]
        }
    } else { // For non-merge-request builds
        // For branch integration_RSU
        if(env.BRANCH_NAME == "integration_RSU")
        {
            enabledOptionalStages = [
                'Run bat files for bootloader',
                'VCPU Bootloader Unit Test',
                'VCPU Bootloader Component Test',
                'VCPU Application Unit Test',
                'Run bat file for APP.DNL and BL.DNL file creation',
                'Generate Output',
                'Archive'
            ]
        }
        // For branch master_RSU
        if(env.BRANCH_NAME == "master_RSU") {
            enabledOptionalStages = [
                'Run bat files for bootloader',
                'VCPU Bootloader Unit Test',
                'VCPU Bootloader Component Test',
                'VCPU Application Unit Test',
                'Run bat file for APP.DNL and BL.DNL file creation',
                'Generate Output',
                'Archive'
            ]
        }
    }
}
// **********/\*****Modul for enabling the optional stages*****/\**********

void stages() {
    enableOptionalStages()
    if (currentBuild.result == 'SUCCESS') { return }
    print("List of enabled optional stages: "+"[\n    \"${enabledOptionalStages.join('",\n    "')}\"\n]")

    def scmVars

    def server = Artifactory.server 'default-artifactory-server-id'
    server.credentialsId = 'apricot-artifactory'

    String path7Z = '"C:\\Program Files\\7-Zip\\7z.exe"'

    def Tools_  = 'tools'
    def Tools   = ".\\${Tools_}"
    def Dwnld_  = 'Dwnld'
    def Dwnld   = ".\\${Dwnld_}"
    def OutDir_ = 'output'
    def OutDir  = ".\\${OutDir_}"
    def OutDir_REL_ = 'output_release'
    def OutDir_BL_ = 'output_bootloader'
    def OutDir_BL  = ".\\${OutDir_BL_}"
    def SwDir_  = 'software'
    def SwDir   = ".\\${SwDir_}"
    // Testfolder
    def OutDir_CT_ = 'software\\VCPU\\test\\component'
    def OutDir_CT = ".\\${OutDir_CT_}"
    def OutDir_UT_ = 'software\\VCPU\\test\\unit'
    def OutDir_UT = ".\\${OutDir_UT_}"
    def OutDir_BL_CT_ = 'software\\bootloader\\test\\component'
    def OutDir_BL_CT = ".\\${OutDir_BL_CT_}"
    def OutDir_BL_UT_ = 'software\\bootloader\\test\\unit'
    def OutDir_BL_UT = ".\\${OutDir_BL_UT_}"

    String zip_name = "output_rsu.zip"
    String zip_name_REL = "output_release_rsu.zip"
    String zip_name_BL = "output_bootloader_rsu.zip"
    String zip_name_CT = "test_report_vcpu_component_tests_rsu.zip"
    String zip_name_UT = "test_report_vcpu_unit_tests_rsu.zip"
    String zip_name_BL_CT = "test_report_bootloader_component_tests_rsu.zip"
    String zip_name_BL_UT = "test_report_bootloader_unit_tests_rsu.zip"
    String zip_full_name = "${WORKSPACE}\\${OutDir_}\\${zip_name}"
    String zip_full_name_REL = "${WORKSPACE}\\${OutDir_REL_}\\${zip_name_REL}"
    String zip_full_name_BL = "${WORKSPACE}\\${OutDir_BL_}\\${zip_name_BL}"
    String zip_full_name_CT = "${WORKSPACE}\\${OutDir_CT_}\\${zip_name_CT}"
    String zip_full_name_UT = "${WORKSPACE}\\${OutDir_UT_}\\${zip_name_UT}"
    String zip_full_name_BL_CT = "${WORKSPACE}\\${OutDir_BL_CT_}\\${zip_name_BL_CT}"
    String zip_full_name_BL_UT = "${WORKSPACE}\\${OutDir_BL_UT_}\\${zip_name_BL_UT}"

    def GenDir_ = 'generated'
    def TmpDir_ = 'temp'
    def BinDir_ = 'bin'

    // Need this for testing if NOT cleand WS.
    def ao = '-y'

    // IDEA: Create a DIR list of Dwnld to ./tools/ and check at ZIP if EXISTs.
    stage('Status')
    {
        bat("echo WORKSPACE=${WORKSPACE}") //C:\jenkins\workspace\xel39c0_JenkinsFile_Deletion_fix
        bat("echo JOB_BASE_NAME=${JOB_BASE_NAME}") //xel39c0_JenkinsFile_Deletion_fix
        bat("echo zip_name=${zip_name}") //output-xel39c0_JenkinsFile_Deletion_fix-XX.zip
        bat("echo zip_name_REL=${zip_name_REL}") //output-xel39c0_JenkinsFile_Deletion_fix-XX.zip
        bat("echo zip_full_name=${zip_full_name}") //C:\jenkins\workspace\xel39c0_JenkinsFile_Deletion_fix\output\xel39c0_JenkinsFile_Deletion_fix\output-xel39c0_JenkinsFile_Deletion_fix-XX.zip
        bat("echo zip_full_name_REL=${zip_full_name_REL}") //C:\jenkins\workspace\xel39c0_JenkinsFile_Deletion_fix\output\xel39c0_JenkinsFile_Deletion_fix\output-xel39c0_JenkinsFile_Deletion_fix-XX.zip
        bat("echo zip_name_BL=${zip_name_BL}") //output-xel39c0_JenkinsFile_Deletion_fix-XX.zip
        bat("echo zip_full_name_BL=${zip_full_name_BL}") //C:\jenkins\workspace\xel39c0_JenkinsFile_Deletion_fix\output\xel39c0_JenkinsFile_Deletion_fix\output-xel39c0_JenkinsFile_Deletion_fix-XX.zip
        bat("echo zip_name_UT=${zip_name_UT}")
        bat("echo zip_full_name_UT=${zip_full_name_UT}")

        bat("echo gitlabBranch=${env.gitlabBranch}") //xel39c0_JenkinsFile_Deletion_fix
        bat("echo gitlabSourceBranch=${env.gitlabSourceBranch}") //xel39c0_JenkinsFile_Deletion_fix
        bat("echo gitlabTargetBranch=${env.gitlabTargetBranch}") //xel39c0_JenkinsFile_Deletion_fix

        bat("set")
        bat("if not exist ${Tools}\\NUL  mkdir ${Tools}")
        bat("if not exist ${Dwnld}\\NUL  mkdir ${Dwnld}")
        bat("if not exist ${OutDir}\\NUL mkdir ${OutDir}")
        bat("if not exist ${SwDir}\\NUL  mkdir ${SwDir}")
        // Test ,both component and unit testing
        bat("if not exist ${Tools}\\test\\NUL  mkdir ${Tools}\\test")
    }

    Map tasks = [failFast: true]

    tasks['Download & unzip tools'] = {
        List<String> listTools = [
            'Vector_RSU.7z',
            'FrancaConnector/FrancaConnector-a28bfd1.7z',
            'EB_tresos_Application_RSU_V01.7z',
            'strawberry-perl2.7z',
            'tasking.7z',
            'python-3.7.6-embed-win-amd64.7z',
            'EB_tresos_BootLoader_RSU_V02.7z',
            'DaimlerSecurityPlugin.7z',
            'strawberry-perl2.7z',
            'test/Python27.7z',
            'test/MinGW.7z',
            'test/lcov.7z',
            'test/Python39.7z',
            'test/strawberry-perl2.7z',
            'test/DocBook_engine.7z'
        ]
        List<String> listNCDs = [
//            'ETFW_NCD/HEADUNIT1_STAR_3_2020_29a.zip',
//            'ETFW_NCD/HEADUNIT2_STAR_3_2020_29a.zip',
//            'ETFW_NCD/STAR_3_MAIN_2020_2020_29a0.zip',
        ]
        List<String> listDwnlds = listTools + listNCDs

        // This stage only dwnlds files which do NOT exist in ./Dwnld/ so we use this as "Update-List".
        // Be careful with the paths: Always the Artifactory path is pre-leading.
        stage('Download tools')
        {
            String downloadSpec = listDwnlds.collect { "apricot/VCPU/tools/${it}"
                }.collect{ "{\"pattern\": \"${it}\", \"target\": \"${WORKSPACE}/${Dwnld_}/\"}"
                }.join(',')
            server.download spec: "{\"files\": [${downloadSpec}]}"
        }

        stage('Unzip tools')
        {
            bat("tree /A /F ${Dwnld_}")
            bat('dir')

            listTools.each {
                String folderOutput = Tools

                if (it.startsWith('test/')) {
                    folderOutput += '\\test'
                }

                bat("${path7Z} x ${ao} -o${folderOutput} -- ${WORKSPACE}\\${Dwnld_}\\VCPU\\${Tools_}\\${it.replace('/', '\\')}")
            }

            bat('dir tools')
            bat('dir tools\\EB_tresos_Studio\\bin')
            bat('dir tools\\EB_tresos_Studio_BL\\bin')
        }
    }

    tasks['Checkout'] = {
        stage('Checkout')
        {
            if(!(scmCheck(verbose: true).infosFound)) {
                error("No info for SCM available. Build can not proceed without SCM infos.")
            }
            String gitCacheDir = "C:\\Jenkins\\cache\\git"
            String repoUrl = scmCheck().repoUrl
            String repoName = (repoUrl.split("/")[3..-1].join("/") - ".git").replaceAll("/","\\\\")
            String cloneReference = "${gitCacheDir}\\${repoName}\\.git"

            dir(SwDir)
            {
                bat('dir')

                scmVars = gitFullClone(gitCacheDir, repoUrl, repoName, cloneReference)

                bat('dir')
                bat('dir VCPU')
                bat('dir bootloader')
            }
        }
    }

    parallel tasks

    // Initialization for mbient-pipeliner-depot functionality
    List<String> patternsJenkins = [OutDir_, OutDir_REL_, OutDir_BL_, OutDir_UT_].collect { "${it}/**/*.zip" }
    Map<String, String> patternsArtifactory = [
        "${OutDir_}": zip_name, "${OutDir_REL_}": zip_name_REL, "${OutDir_BL_}": zip_name_BL,
        "${OutDir_UT_}": zip_name_UT]
//        "${OutDir_CT_}": zip_name_CT, "${OutDir_BL_CT_}": zip_name_BL_CT, "${OutDir_BL_UT_}": zip_name_BL_UT,
//        "${Dwnld_}/VCPU/tools/ETFW_NCD": "*"]
    Map<String, String> patternsDocs = [:]
    ArtifactsArchiver archiver = new ArtifactsArchiver(this, env, scmVars,
        patternsJenkins, patternsArtifactory, patternsDocs)
    CommonStages commonStages = new CommonStages(this, env.getEnvironment())

    // Set Environment Variables
    env.VCPU_REVISION = scmVars.GIT_COMMIT
    env.START_TIME_IN_MILLIS = currentBuild.startTimeInMillis

//    stage('Enable GLIWA build', optional: true)
//    {
//        dir('software\\VCPU\\util')
//        {
//            bat('DEL launch_cfg.bat')
//            def status = bat returnStatus: true, script: "REN launch_gliwa_cfg.bat launch_cfg.bat"
//            println "REN (rename) returned ${status}"
//            if (status == 0) {
//                println "Enabled GLIWA build."
//                println "===============Content of launch_cfg.bat:==============="
//                bat('type launch_cfg.bat')
//                println "===================================================="
//            } else {
//                error("REN failed")
//            }
//        }
//    }

    stage('Update EB tresos License File')
    {
        String outFile = "${Tools}\\EB_tresos_Studio\\bin\\flexlm.cfg"
        String outFile_BL = "${Tools}\\EB_tresos_Studio_BL\\bin\\flexlm.cfg"

        String newContent = "27056@smtcagp00024.rd.corpintra.net\r\n"
        writeFile file: "${outFile}", text: newContent
        writeFile file: "${outFile_BL}", text: newContent
        bat("type ${outFile}")
        bat("type ${outFile_BL}")
        bat('echo')
    }

    stage('Update Tasking Complier License File')
    {
        def outFile = "${Tools}\\tasking\\v6.2r2\\etc\\licopt.txt"
        bat("type ${outFile}")
        String newContent = "TSK_LICENSE_KEY_SW160800 = PRODUCT\r\n"
        newContent = newContent+"TSK_LICENSE_SERVER = smtcagp00024.rd.corpintra.net:9090\r\n"
        newContent = newContent+"TSK_NO_ANONYMOUS\r\n"
        writeFile file: "${outFile}", text: newContent
        bat("type ${outFile}")
        bat('echo')
    }

    stage('Fixup extra_plugins link file')
    {
        def outFile = "${Tools}\\EB_tresos_Studio\\links\\vcpu_extra_plugins.link"

        def newContent = "path=../../../software/extra_plugins\r\n"

        writeFile file: "${outFile}", text: newContent
        bat("type ${outFile}")
        bat('echo')
    }

    if (archiver.promoteParamSetup() && !archiver.currentAndPromoteBranchDiffer("${SwDir_}")) {
        println("Nothing to release. Current hash already exists in branch ${env.PIP_PROMOTE_BRANCH}")
        commonStages.skipPromote()
        return
    }

    stage('Update BATch hardcoded values - temporary')
    {
        def inFile = "software\\VCPU\\util\\launch_cfg.bat"
        def outFile = "${inFile}"
        bat("echo BATch: \"${inFile}\"")
        bat("type ${inFile}")
        String readContent = readFile("${inFile}")
        String newContent = readFile("${inFile}").replaceAll('27000@licsrv-de.ebgroup.elektrobit.com', '27056@smtcagp00024.rd.corpintra.net')
        //.replaceAll('/.*SET *EB_LICENSE_FILE=.*/', 'SET EB_LICENSE_FILE=27056@smtcagp00024.rd.corpintra.net')
        writeFile file: "${outFile}", text: newContent
        bat("type ${outFile}")
        assert newContent != readContent

        // Bootloader
        def inFile_BL = "software\\bootloader\\util\\launch_cfg.bat"
        def outFile_BL = "${inFile_BL}"
        bat("echo BATch: \"${inFile_BL}\"")
        bat("type ${inFile_BL}")
        String readContent_BL = readFile("${inFile_BL}")
        String newContent_BL = readFile("${inFile_BL}").replaceAll('27000@licsrv-de.ebgroup.elektrobit.com', '27056@smtcagp00024.rd.corpintra.net')
        //.replaceAll('/.*SET *EB_LICENSE_FILE=.*/', 'SET EB_LICENSE_FILE=27056@smtcagp00024.rd.corpintra.net')
        writeFile file: "${outFile_BL}", text: newContent_BL
        bat("type ${outFile_BL}")
        assert newContent_BL != readContent_BL
    }
    // SET EB_LICENSE_FILE=27000@licsrv-de.ebgroup.elektrobit.com

    // This is a temporary hack due to malfunction crypt file access during build.
    stage('Attrib code and output')
    {
        // Necessary for the attrib hack:
        bat("if not exist ${SwDir}\\VCPU\\NUL                                     mkdir ${SwDir}\\VCPU")
        bat("if not exist ${SwDir}\\VCPU\\${OutDir_}\\NUL                         mkdir ${SwDir}\\VCPU\\${OutDir_}")
        bat("if not exist ${SwDir}\\VCPU\\${OutDir_}\\${GenDir_}\\NUL             mkdir ${SwDir}\\VCPU\\${OutDir_}\\${GenDir_}")
        bat("if not exist ${SwDir}\\VCPU\\${OutDir_}\\${GenDir_}\\${TmpDir_}\\NUL mkdir ${SwDir}\\VCPU\\${OutDir_}\\${GenDir_}\\${TmpDir_}")
        // Bootloader
        // Necessary for the attrib hack:
        bat("if not exist ${SwDir}\\bootloader\\NUL                                     mkdir ${SwDir}\\bootloader")
        bat("if not exist ${SwDir}\\bootloader\\${OutDir_}\\NUL                         mkdir ${SwDir}\\bootloader\\${OutDir_}")
        bat("if not exist ${SwDir}\\bootloader\\${OutDir_}\\${GenDir_}\\NUL             mkdir ${SwDir}\\bootloader\\${OutDir_}\\${GenDir_}")
        bat("if not exist ${SwDir}\\bootloader\\${OutDir_}\\${GenDir_}\\${TmpDir_}\\NUL mkdir ${SwDir}\\bootloader\\${OutDir_}\\${GenDir_}\\${TmpDir_}")

        dir('.')
        {
            bat("attrib -R ${SwDir}  /S /D")
            bat("attrib -R ${OutDir} /S /D")
            //bat("attrib -R ${Tools}\\EB_tresos_Autocore\\eclipse   /S /D")
            bat("attrib -R ${Tools}\\EB_tresos_Studio\\eclipse   /S /D")

            // Necessary for the attrib hack:
            bat("if not exist ${SwDir}\\VCPU\\${OutDir_}\\NUL                         mkdir ${SwDir}\\VCPU\\${OutDir_}")
            bat("if not exist ${SwDir}\\VCPU\\${OutDir_}\\${GenDir_}\\NUL             mkdir ${SwDir}\\VCPU\\${OutDir_}\\${GenDir_}")
            bat("if not exist ${SwDir}\\VCPU\\${OutDir_}\\${GenDir_}\\${TmpDir_}\\NUL mkdir ${SwDir}\\VCPU\\${OutDir_}\\${GenDir_}\\${TmpDir_}")

            bat("if not exist ${SwDir}\\VCPU\\${OutDir_}\\${BinDir_}\\NUL             mkdir ${SwDir}\\VCPU\\${OutDir_}\\${BinDir_}")

            bat("attrib -R ${SwDir}\\VCPU\\${OutDir_}\\${GenDir_}\\${TmpDir_} /S /D")
            bat("echo '' > ${SwDir}\\VCPU\\${OutDir_}\\${GenDir_}\\${TmpDir_}\\crypto_dummy.tmp")
            bat("attrib -R ${SwDir}\\VCPU\\${OutDir_}\\${GenDir_}\\${TmpDir_}\\crypto_dummy.tmp /S /D")

            bat("attrib -R ${SwDir}\\VCPU\\${OutDir_}\\${BinDir_} /S /D")
            bat("echo '' > ${SwDir}\\VCPU\\${OutDir_}\\${BinDir_}\\dummy.map")
            bat("attrib -R ${SwDir}\\VCPU\\${OutDir_}\\${BinDir_}\\dummy.map /S /D")

            // bootloader

            // Necessary for the attrib hack:
            bat("if not exist ${SwDir}\\bootloader\\${OutDir_}\\NUL                         mkdir ${SwDir}\\bootloader\\${OutDir_}")
            bat("if not exist ${SwDir}\\bootloader\\${OutDir_}\\${GenDir_}\\NUL             mkdir ${SwDir}\\bootloader\\${OutDir_}\\${GenDir_}")
            bat("if not exist ${SwDir}\\bootloader\\${OutDir_}\\${GenDir_}\\${TmpDir_}\\NUL mkdir ${SwDir}\\bootloader\\${OutDir_}\\${GenDir_}\\${TmpDir_}")

            bat("if not exist ${SwDir}\\bootloader\\${OutDir_}\\${BinDir_}\\NUL             mkdir ${SwDir}\\bootloader\\${OutDir_}\\${BinDir_}")

            bat("attrib -R ${SwDir}\\bootloader\\${OutDir_}\\${GenDir_}\\${TmpDir_} /S /D")
            bat("echo '' > ${SwDir}\\bootloader\\${OutDir_}\\${GenDir_}\\${TmpDir_}\\crypto_dummy.tmp")
            bat("attrib -R ${SwDir}\\bootloader\\${OutDir_}\\${GenDir_}\\${TmpDir_}\\crypto_dummy.tmp /S /D")

            bat("attrib -R ${SwDir}\\bootloader\\${OutDir_}\\${BinDir_} /S /D")
            bat("echo '' > ${SwDir}\\bootloader\\${OutDir_}\\${BinDir_}\\TRICORE_TC39XX_bootloader.map")
            bat("attrib -R ${SwDir}\\bootloader\\${OutDir_}\\${BinDir_}\\TRICORE_TC39XX_bootloader.map /S /D")
        }
    }

    // This should be replaced later with a solely more intelligen BATch file.
    stage('Run bat files for Developer Build')
    {
        dir('software\\VCPU\\util')
        {
            bat(label: '', script: 'import.bat && launch.bat && make.bat generate && dir ..\\output\\generated\\include && make.bat 99_psm_dual_build_DEV && make.bat -j16 && generate_binary_and_signature.bat')
        }

        // Copy Lauterbach CMM for development flashing
        dir('software\\VCPU\\util')
        {
            bat(label: '', script: 'launch.bat && cmm_copy.bat')
        }
    }

    /* PSM FUll Functionality Dual Build APRICOT-7408  */
    stage('Run bat files for Full Functionality Build')
    {
        dir('software\\VCPU\\util')
        {
            bat(label: '', script: 'launch.bat && make.bat 99_psm_dual_build_FULL && make.bat -j16 && generate_binary_and_signature.bat')
        }

        // Copy Lauterbach CMM for development flashing
        dir('software\\VCPU\\util')
        {
            bat(label: '', script: 'launch.bat && cmm_copy.bat')
        }
    }


    // This should be replaced later with a solely more intelligen BATch file.
    stage('Run bat files for bootloader', optional: true)
    {
        bat('tree /A /F software\\bootloader\\output')
        dir('software\\bootloader\\util')
        {
            bat(label: '', script: 'import.bat && launch.bat && make.bat generate && make.bat -j16 && generate_binary_and_signature.bat')
        }

        // Copy Lauterbach CMM for development flashing
        dir('software\\bootloader\\util')
        {
            bat(label: '', script: 'launch.bat && cmm_copy.bat')
        }
    }


//    stage ('VCPU Application Unit Test', optional: true)
//    {
//            // copy VectorCast scripts
//            dir('software\\VCPU\\source\\swc\\di-vcpu-tst_fwk\\vectorcast\\ci-tools')
//            {
//                bat label: '', script: 'vc_scripts_copy.cmd'
//            }
//            // run unittest for VCPU Application
//             dir('software\\VCPU\\source\\swc\\di-vcpu-tst_fwk\\vectorcast\\sw-unit-test-vcm')
//            {
//                bat("echo Execute VCPU Apps unit test...")
//                bat(label: '', script: 'UnitTestStart.cmd -j4')
//                bat("echo OK.")
//                bat("echo OK.")
//                bat("echo Publish test results...")
//                junit allowEmptyResults: true, testResults: '**/test_results_*.xml'
//                bat(label: '', script: 'dir')
//                bat(label: '', script: '%WORKSPACE%\\tools\\test\\Python27\\python.exe -m pip install lxml')
//                bat(label: '', script: '%WORKSPACE%\\tools\\test\\Python27\\python.exe UpdateVcast-report_2019sp2.py')
//            }
//
//            bat("echo Publish unit test HTML full report..")
//            publishHTML([
//            allowMissing: false,
//            alwaysLinkToLastBuild: false,
//            keepAll: true,
//            reportDir: 'software\\VCPU\\source\\swc\\di-vcpu-tst_fwk\\vectorcast\\sw-unit-test-vcm',
//            reportFiles: '*_function_full_report.html, management\\**_TestSuite.html',
//            reportName: 'Unit test HTML Report',
//            reportTitles: 'VCAST  Unit code Coverage reports'])
//            bat("echo OK.")
//
//    }
//
//    stage ('VCPU Application Component Test', optional: true)
//    {
//            // run component test for VCPU Application
//            dir('software\\VCPU\\source\\swc\\di-vcpu-tst_fwk\\vectorcast\\sw-cmp-test-vcm')
//            {
//                bat("echo Execute VCPU Apps component test...")
//                bat(label: '', script: 'CompTestStart.cmd -j4')
//                bat("echo OK.")
//                bat("echo Publish test results...")
//                junit allowEmptyResults: true, testResults: '**/test_results_*.xml'
//                bat("echo OK.")
//            }
//
//            bat("echo Publish component test HTML full report..")
//            publishHTML([
//            allowMissing: false,
//            alwaysLinkToLastBuild: false,
//            keepAll: true,
//            reportDir: 'software\\VCPU\\source\\swc\\di-vcpu-tst_fwk\\vectorcast\\sw-cmp-test-vcm',
//            reportFiles: '*_full_report.html, management\\**_TestSuite.html',
//            reportName: 'Component test HTML Report',
//            reportTitles: 'VCAST Component code Coverage reports'])
//            bat("echo OK.")
//    }
//
//    stage ('VCPU Application Integration Test', optional: true)
//    {
//            // run Sw Integration test for VCPU Application
//            dir('software\\VCPU\\source\\swc\\di-vcpu-tst_fwk\\vectorcast\\sw-int-test-vcm')
//            {
//                bat("echo Execute VCPU Apps Sw Integration test...")
//                bat(label: '', script: 'SWIntTestStart.cmd -j4')
//                bat("echo OK.")
//                bat("echo Publish test results...")
//                junit allowEmptyResults: true, testResults: '**/test_results_*.xml'
//                bat("echo OK.")
//            }
//
//            bat("echo Publish sw integration test HTML full report..")
//            publishHTML([
//            allowMissing: false,
//            alwaysLinkToLastBuild: false,
//            keepAll: true,
//            reportDir: 'software\\VCPU\\source\\swc\\di-vcpu-tst_fwk\\vectorcast\\sw-int-test-vcm',
//            reportFiles: '*_full_report.html, management\\**_TestSuite.html',
//            reportName: 'Sw Integration test HTML Report',
//            reportTitles: 'VCAST Sw Integration Coverage reports'])
//            bat("echo OK.")
//    }

    stage('VCPU Application Unit Test', optional: true)
    {
        dir("${SwDir}\\VCPU\\test")
        {
            bat(label: '', script: 'unit_test.bat')
            bat("echo Publish test results...")
            junit allowEmptyResults: true, testResults: '**/testresult.xml'
            bat("echo OK.")
        }
        dir("${SwDir}\\VCPU\\test\\unit")
        {
            bat("echo Publish VCPU Application Unit test results on videowall")
            powershell 'Invoke-WebRequest -Uri "https://videowall.swf.daimler.com/endpoint/api/v1/test-runs" -Method POST -InFile "test-results-data.json" -ContentType "application/json"'
            bat("echo OK.")
            //API is depricated and will be fetched from the meta.yaml file
            /*
            bat("echo Publish Coverage Report on videowall")
            powershell 'Invoke-WebRequest -Uri "https://videowall.swf.daimler.com/endpoint/api/v1/swf/code-coverage" -Method POST -InFile "coverage-data.json" -ContentType "application/json"'
            bat("echo OK.")
            */
        }
        archiveTestResultsforCoverage("**/cobertura.xml")
        archiveTestResultsforCoverage("**/coverage.xml")
    }

    stage('VCPU Bootloader Unit Test', optional: true)
    {
        dir("${SwDir}\\bootloader\\test")
        {
            bat(label: '', script: 'unit_test.bat')
            bat("echo Publish test results...")
            junit allowEmptyResults: true, testResults: '**/testresult.xml'
            bat("echo OK.")
        }
        dir("${SwDir}\\bootloader\\test\\unit")
        {
            bat("echo Publish Bootloader Uint test results on videowall")
            powershell 'Invoke-WebRequest -Uri "https://videowall.swf.daimler.com/endpoint/api/v1/test-runs" -Method POST -InFile "test-results-data.json" -ContentType "application/json"'
            bat("echo OK.")
            bat("echo Publish Coverage Report on videowall")
            powershell 'Invoke-WebRequest -Uri "https://videowall.swf.daimler.com/endpoint/api/v1/swf/code-coverage" -Method POST -InFile "coverage-data.json" -ContentType "application/json"'
            bat("echo OK.")
        }
    }

    stage('VCPU Bootloader Component Test', optional: true)
    {
        dir("${SwDir}\\bootloader\\test")
        {
            bat(label: '', script: 'component_test.bat')
        }
    }

//    stage('Run bat file for VCPU component tests', optional: true)
//    {
//        dir("${SwDir}\\VCPU\\test")
//        {
//            bat(label: '', script: 'component_test.bat')
//        }
//        if (env.gitlabActionType == "PUSH" && env.gitlabSourceBranch == env.gitlabTargetBranch) {
//            dir("${SwDir}\\VCPU\\test\\component")
//            {
//                bat("echo Publish component test results on videowall")
//                powershell 'Invoke-WebRequest -Uri "https://videowall.swf.daimler.com/endpoint/api/v1/test-runs" -Method POST -InFile "test-results-data.json" -ContentType "application/json"'
//
//                bat("echo Publish Coverage Report on videowall")
//                powershell 'Invoke-WebRequest -Uri "https://videowall.swf.daimler.com/endpoint/api/v1/swf/code-coverage" -Method POST -InFile "coverage-data.json" -ContentType "application/json"'
//            }
//        }
//    }

    stage('Run bat file for APP.DNL and BL.DNL file creation', optional: true)
    {
        dir("${SwDir}\\VCPU\\util\\dnl_create")
        {
            bat(label: '', script: 'dnl_app_create.bat')
            bat(label: '', script: 'dnl_bl_create.bat')
        }
    }

//    stage('Archive for MR to BootloaderIntegration_Bosch', optional: true)
//    {
//        String arcDirDev = "Application-dev-ignition-off"
//        String arcDirRel = "Application-release"
//        String arcDirBL = "Bootloader"
//
//        robocopy("${SwDir_}\\VCPU\\output\\bin ${arcDirRel} *.bin")
//        robocopy("${SwDir_}\\VCPU\\output\\binDeveloper ${arcDirDev} *.bin")
//        robocopy("${SwDir_}\\bootloader\\output\\bin ${arcDirBL} *.bin")
//        robocopy("${SwDir_}\\bootloader\\output\\bin ${arcDirBL} *.elf")
//        robocopy("${SwDir_}\\bootloader\\output\\bin ${arcDirBL} *.dnl")
//
//        tasks = [failFast: true]
//        Map<String, String> dirPattern = [
//            "${arcDirDev}": "\"output.zip\" *.bin",
//            "${arcDirRel}": "\"output_release.zip\" *.bin",
//            "${arcDirBL}": "\"output_bootloader.zip\" *.bin *.elf",
//        ]
//
//        dirPattern.each { k, v ->
//            tasks[k] = {
//                dir(k)
//                {
//                    bat("${path7Z} a -r -- ${v}")
//                }
//            }
//        }
//
//        parallel tasks
//
//        List<String> patternsJenkinsSUB = [
//            "${arcDirDev}/*.bin",
//            "${arcDirDev}/*.zip",
//            "${arcDirRel}/*.bin",
//            "${arcDirRel}/*.zip",
//            "${arcDirBL}/*.bin",
//            "${arcDirBL}/*.zip",
//            "${arcDirBL}/*.elf"
//            "${arcDirBL}/*.dnl"
//        ]
//        Map<String, String> patternsArtifactorySUB = [
//            "${arcDirDev}": "output.zip", "${arcDirRel}": "output_release.zip", "${arcDirBL}": "output_bootloader.zip"]
//        Map<String, String> patternsDocsSUB = [:]
//        ArtifactsArchiver archiverSUB = new ArtifactsArchiver(this, env, scmVars,
//            patternsJenkinsSUB, patternsArtifactorySUB, patternsDocsSUB)
//        archiverSUB.archive()
//    }

    stage('Generate Output', optional: true)
    {
        dir('software\\VCPU')
        {
            robocopy("${OutDir_} ${OutDir_REL_} /E")
            dir('output')
            {
                bat('RD /S /Q bin')
                bat('REN binDeveloper bin')
            }
            dir('output_release')
            {
                bat('RD /S /Q binDeveloper')
            }
        }

        tasks = [failFast: true]
        Map<String, String> dirPattern = [
            "${SwDir}\\VCPU\\output": "\"${zip_full_name}\" *",
            "${SwDir}\\VCPU\\output_release": "\"${zip_full_name_REL}\" *",
            "${SwDir}\\bootloader\\output": "\"${zip_full_name_BL}\" *",
//            "${OutDir_CT}": "\"${zip_full_name_CT}\" *.html *.xml documentation\\*.pdf",
//            "${OutDir_BL_CT}": "\"${zip_full_name_BL_CT}\" *.html *.xml *.json documentation\\*.pdf",
//            "${OutDir_BL_UT}": "\"${zip_full_name_BL_UT}\" *.html *.xml *.json documentation\\*.pdf",
            "${OutDir_UT}": "\"${zip_full_name_UT}\" *.html *.xml *.json *.info documentation\\*.pdf",
        ]

        dirPattern.each { k, v ->
            tasks[k] = {
                dir(k)
                {
                    bat("${path7Z} a -r -- ${v}")
                }
            }
        }

        parallel tasks
    }

    stage("Archive inside Jenkins", optional: true) {
        patternsJenkins.each{
            archiveArtifacts artifacts: it
        }
    }

    stage("Archive", optional: true) {
        archiver.archive()
    }

//    mrVars = parseMergeRequest(env.gitlabMergeRequestDescription)
//    if (commonStages.isTrue(env.PIP_SYSTEM_TEST) || commonStages.isTrue(mrVars['system_test'])) {
//        String stagingUrl = ""
//        if (scmCheck().isMerge) {
//            stagingUrl = "https://artifact.swf.daimler.com/${archiver.getTargetPath(false)}"
//        } else {
//            stagingUrl = "https://artifact.swf.daimler.com/${archiver.getTargetPath(true)}"
//        }
//        Map parallelTests = [:]
//        String[] testConfigurations
//        if (mrVars['system_test_configurations']) {
//            testConfigurations = mrVars['system_test_configurations'].split(",")
//        } else if (env.PIP_SYSTEM_TEST_CONFIGURATIONS) {
//            testConfigurations = env.PIP_SYSTEM_TEST_CONFIGURATIONS.split(",")
//        } else {
//            testConfigurations = ['SST:apricotbscqal/verification.system-test-vcpu.downstream::required']
//        }
//
//        testConfigurations.each { testConfiguration ->
//            def (String name, String job, String testSet, String priority) = testConfiguration.trim().split(":")
//            parallelTests["${name}"] = {
//                stage("${name}") {
//                    commonStages.stageSystemTest("VCPU_URL", stagingUrl, testSet, job, priority)
//                }
//            }
//        }
//        parallel parallelTests
//    }

    if (archiver.promoteParamSetup()) {
        stage("Archive..") {
            archiver.archive()
        }
        stage("Push release to master") {
            dir("${SwDir_}") {
                Boolean allowUnstablePromote = "true".equalsIgnoreCase(env.PIP_PROMOTE_UNSTABLE)
                archiver.pushReleaseToMaster(env.PIP_PROMOTE_BRANCH, allowUnstablePromote)
            }
        }
    }
}

def archiveTestResultsforCoverage(String patternPath)
{
    try
    {
        archiveArtifacts artifacts: patternPath, followSymlinks: true
    }
    catch(e)
    {
        print e
    }
}
node(env.PIP_LABELS?.trim() ? env.PIP_LABELS : "CloudVCPU")
{
    Logger.init(this)

    try {
        sshagent(["apricot-jenkins-ssh"]) {
            stages()
        }
    } finally {
        stage("Finally Cleanup")
        {
            step([$class: 'WsCleanup'])
        }
    }
} //node
//
// EOF
