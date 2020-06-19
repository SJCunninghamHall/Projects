namespace Chops
{
    partial class frmCUT
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(frmCUT));
            frmCUT frmCUT = this;
            frmCUT.btnChop = new System.Windows.Forms.Button();
            frmCUT.nudMaxConsec = new System.Windows.Forms.NumericUpDown();
            frmCUT.txtSource = new System.Windows.Forms.RichTextBox();
            frmCUT.txtChoppeds = new System.Windows.Forms.RichTextBox();
            ((System.ComponentModel.ISupportInitialize)frmCUT.nudMaxConsec).BeginInit();
            frmCUT.SuspendLayout();
            // 
            // btnChop
            // 
            frmCUT.btnChop.Location = new System.Drawing.Point(305, 371);
            frmCUT.btnChop.Name = "btnChop";
            frmCUT.btnChop.Size = new System.Drawing.Size(75, 23);
            frmCUT.btnChop.TabIndex = 2;
            frmCUT.btnChop.Text = "&Chop";
            frmCUT.btnChop.UseVisualStyleBackColor = true;
            frmCUT.btnChop.Click += new System.EventHandler(frmCUT.btnChop_Click);
            // 
            // nudMaxConsec
            // 
            frmCUT.nudMaxConsec.Location = new System.Drawing.Point(679, 192);
            frmCUT.nudMaxConsec.Name = "nudMaxConsec";
            frmCUT.nudMaxConsec.Size = new System.Drawing.Size(54, 20);
            frmCUT.nudMaxConsec.TabIndex = 3;
            // 
            // txtSource
            // 
            frmCUT.txtSource.Location = new System.Drawing.Point(13, 13);
            frmCUT.txtSource.Name = "txtSource";
            frmCUT.txtSource.Size = new System.Drawing.Size(659, 173);
            frmCUT.txtSource.TabIndex = 4;
            frmCUT.txtSource.Text = resources.GetString("txtSource.Text");
            frmCUT.txtSource.Leave += new System.EventHandler(frmCUT.txtSource_LostFocus);
            // 
            // txtChoppeds
            // 
            frmCUT.txtChoppeds.Location = new System.Drawing.Point(13, 192);
            frmCUT.txtChoppeds.Name = "txtChoppeds";
            frmCUT.txtChoppeds.Size = new System.Drawing.Size(659, 173);
            frmCUT.txtChoppeds.TabIndex = 5;
            frmCUT.txtChoppeds.Text = "";
            // 
            // frmCUT
            // 
            frmCUT.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            frmCUT.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            frmCUT.ClientSize = new System.Drawing.Size(738, 405);
            frmCUT.Controls.Add(frmCUT.txtChoppeds);
            frmCUT.Controls.Add(frmCUT.txtSource);
            frmCUT.Controls.Add(frmCUT.nudMaxConsec);
            frmCUT.Controls.Add(frmCUT.btnChop);
            frmCUT.Name = "frmCUT";
            frmCUT.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            frmCUT.Text = "C.U.T";
            ((System.ComponentModel.ISupportInitialize)frmCUT.nudMaxConsec).EndInit();
            frmCUT.ResumeLayout(false);

        }

        #endregion
        private System.Windows.Forms.Button btnChop;
        private System.Windows.Forms.NumericUpDown nudMaxConsec;
        private System.Windows.Forms.RichTextBox txtSource;
        private System.Windows.Forms.RichTextBox txtChoppeds;
    }
}

