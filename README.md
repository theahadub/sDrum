 sDrum 
 
 ![sDrum](https://github.com/theahadub/sDrum/assets/144957682/db06ef92-022b-4598-a15f-fc6d1593aa6f)

swiftDialog wrapped around Adobe RUM

 This script will use Adobe's Remote Update Manager (RUM) to update the Adobe apps
 This should improve on the gui feedback since each app can take 5-20 minutes to update
   leaving the end user wondering if it is working or locked up.

 This will lets users select which apps they want updated or not.

 RUM will only update installed Adobe apps and does not upgrade the app so 11.0.1 to 11.1
     and not 11.1 to 12.1
 The app just has to be installed and does not need to be signed in so this can run after 
     the 1st install before the user logs into Creative Cloud.
 RUM polls Adobe Update server or the local Adobe Update Server if set up using the 
     Adobe Update Server Setup Tool (AUSST). RUM deploys the latest updates available on 
     update server to each client machine on which it is run. (see code url below)

Make a package that delivers the icons to /Library/Management/sdrum/Branding/Icons/.  
The script will clone the CreativeCloud.png to make an icon for a code not already present.
You can go in later and make an icon for the Adobe Code.

 This script was inspired by 
   Martin Piron's: https://github.com/ooftee/Dialog-StarterKit
   John Mahlman's Adobe-Rum with progress: https://github.com/jmahlman/Mac-Admin-Scripts
   Dan Snelson's Setup Your Mac via swiftDialog https://snelson.us/sym
       and https://snelson.us/2024/02/inventory-update-progress/ 
   Trevor Sysock aka @BigMacAdmin on Slack
       https://github.com/SecondSonConsulting/swiftDialogExamples/blob/main/checklistJSONexample.sh

 Based on these documents, rules, and limitations (May 14, 2024)
   Adobe RUM Rules and limitations: https://helpx.adobe.com/enterprise/using/using-remote-update-manager.html
   Adobe SAP Code list: https://helpx.adobe.com/enterprise/package/help/apps-deployed-without-their-base-versions.html
   Adobe Uninstaller: https://helpx.adobe.com/enterprise/using/uninstall-creative-cloud-products.html

