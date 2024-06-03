# sDrum
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
     update server to each client machine on which it is run.
