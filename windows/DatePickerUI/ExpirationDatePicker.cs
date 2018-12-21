using Microsoft.Deployment.WindowsInstaller;
using System;
using System.Windows.Forms;
using System.Drawing;

namespace USTCustomActions
{
    public class ExpirationDatePicker
    {

        MonthCalendar calendar;
        Form form;
        Session session;

        public ExpirationDatePicker(Session session)
        {
            this.session = session;
        }

        public ExpirationDatePicker(){}

        public void LaunchForm()
        {

            Button cancel = new Button
            {
                Text = "Cancel",
                Location = new Point(0, 198),
                Size = new Size(95,30)             
            };

            Button select = new Button
            {
                Text = "Select",
                Location = new Point(100, 198),
                Size = new Size(95, 30)
            };

            MonthCalendar mc = new MonthCalendar
            {
                ShowTodayCircle = false,
                SelectionStart = getStartDate(),
                MaxSelectionCount = 1,                
                MinDate = DateTime.Today.AddDays(1),
                Margin = new Padding(0),
            };       

            select.Click += new EventHandler(this.SelectButton);

            Form form = new Form
            {
                Font = new Font("Calibri", 10.2F, FontStyle.Regular, GraphicsUnit.Point, ((byte)(0))),
                CancelButton = cancel,
                Name = "Certificate Expiration",
                FormBorderStyle = FormBorderStyle.FixedDialog,
                StartPosition = FormStartPosition.CenterScreen,
                AutoSize = true,
                AutoSizeMode = AutoSizeMode.GrowAndShrink,
                MinimizeBox = false,
                MaximizeBox = false,
            };

            form.Controls.Add(mc);
            form.Controls.Add(cancel);
            form.Controls.Add(select);

            this.calendar = mc;
            this.form = form;
          
            form.ShowDialog();

        }

        public static DateTime getStartDate () {
            return DateTime.Today.AddYears(10);
        }

        private void SelectButton(Object sender, EventArgs e)
        {
           if (this.session != null)
            {               
                this.session["SUBJECT_DATE_TEXT"] = calendar.SelectionRange.Start.ToString("MM/dd/yyyy");
                this.form.Close();                
            }
        }
    }
}
