using AdobeCertGen;
using System;
using System.IO;
using System.Windows.Forms;


namespace certgen
{
    public partial class title : Form
    {

        FolderBrowser2 dialog = new FolderBrowser2();
        String outDir;

        public title()
        {
            InitializeComponent();
            customSetup();

        }

        private String trimDir(String dir)
        {
            return (dir.Length > 43) ? dir.Substring(0, 40) + "..." : dir;
        }

        private void customSetup()
        {

            String defaultDirectory = Directory.GetCurrentDirectory();

            this.dialog.DirectoryPath = defaultDirectory;
            outputPath.Text = trimDir(defaultDirectory);
            this.outDir = defaultDirectory;
            countryCode.SelectedIndex = 0;

            expDate.Value = Util.GetInitialDate();

        }

        private void btnBrowse_Click(object sender, EventArgs e)
        {

            if (dialog.ShowDialog(null) == DialogResult.OK )
            {
                outputPath.Text = trimDir(dialog.DirectoryPath);
                this.outDir = dialog.DirectoryPath;
            }
    
        }

        private void btnRandomize_Click(object sender, EventArgs e)
        {
            Subject s = new Subject();

            emailAddress.Text = s.EmailAddress;
            commonName.Text = s.CommonName;            
            locality.Text = s.Locality;
            orgName.Text = s.OrgName;
            orgUnit.Text = s.OrgUnit;
            stateName.Text = s.StateName;
            countryCode.SelectedIndex = new Random().Next(0, 251);
        }

        private void btnGenerate_Click(object sender, EventArgs e)
        {
            try
            {
                Certificate c = new Certificate(
                    (new Subject(
                    countryCode.Text,
                    stateName.Text,
                    locality.Text,
                    orgName.Text,
                    orgUnit.Text,
                    commonName.Text,
                    emailAddress.Text,
                    DateTime.Parse(expDate.Text).AddHours(1)
                    )));


                Util.WriteCredentials(c, this.outDir);

                MessageBox.Show(
                    "Success! Cert/key pair generated to: \n\n"
                    + outputPath.Text,
                    "Success",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Information);

                Application.Exit();
            } catch (Exception ex)
            {     
                MessageBox.Show(
                    "Error generating certificate! Message: \n\n\"" 
                    + ex.Message + "\"", 
                    "Error occured",
                    MessageBoxButtons.OK, 
                    MessageBoxIcon.Error);
            }

        }

        private void btnExit_Click(object sender, EventArgs e)
        {
            Application.Exit();
        }

        private void title_Load(object sender, EventArgs e)
        {

        }
    }
}

