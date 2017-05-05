using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;

//Add For PowerShell Invocation
using System.Collections.ObjectModel;
using System.Management.Automation;
using System.Management.Automation.Runspaces;

[ComVisible(true)]

public class PowerShellHelper {
    Runspace runspace;
    public PowerShellHelper() {
        runspace = RunspaceFactory.CreateRunspace();
        runspace.Open();
    }

    public PowerShellHelper(Runspace remoteRunspace) {
        runspace = remoteRunspace;
    }

    void InvokePowerShell(string cmd, dynamic callbackFunc) {
        using (PowerShell PowerShellInstance = PowerShell.Create()) {
            PowerShellInstance.AddScript(cmd);

            Collection<PSObject> results = PowerShellInstance.Invoke();

            //Convert records to strings
            StringBuilder stringBuilder = new StringBuilder();
            if (PowerShellInstance.HadErrors) {
                foreach(var errorRecord in PowerShellInstance.Streams.Error) {
                    stringBuilder.Append(errorRecord.ToString());
                }
            } else {
                foreach(PSObject obj in results) {
                    stringBuilder.Append(obj);
                }
            }
            callbackFunc(stringBuilder.ToString());
        }
    }

    public void runPowerShell(string cmd, dynamic callbackFunc) {
        new Task(() => { InvokePowerShell(cmd, callbackFunc); }).Start();
    }

    public void resetRunspace() {
        runspace.Close();
        runspace = RunspaceFactory.CreateRunspace();
        runspace.Open();
    }
}