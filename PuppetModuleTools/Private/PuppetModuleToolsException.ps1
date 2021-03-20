# Simple exception handler
class PuppetModuleToolsException: System.Exception {
    $ExceptionMessage
    PuppetModuleToolsException([string]$Message){
        $this.ExceptionMessage=$Message
    }
}