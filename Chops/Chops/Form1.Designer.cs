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
            this.txtOrig = new System.Windows.Forms.TextBox();
            this.txtChopped = new System.Windows.Forms.TextBox();
            this.btnChop = new System.Windows.Forms.Button();
            this.nudMaxConsec = new System.Windows.Forms.NumericUpDown();
            ((System.ComponentModel.ISupportInitialize)(this.nudMaxConsec)).BeginInit();
            this.SuspendLayout();
            // 
            // txtOrig
            // 
            this.txtOrig.Location = new System.Drawing.Point(13, 13);
            this.txtOrig.Multiline = true;
            this.txtOrig.Name = "txtOrig";
            this.txtOrig.ScrollBars = System.Windows.Forms.ScrollBars.Both;
            this.txtOrig.Size = new System.Drawing.Size(659, 173);
            this.txtOrig.TabIndex = 0;
            this.txtOrig.Text = resources.GetString("txtOrig.Text");
            // 
            // txtChopped
            // 
            this.txtChopped.Location = new System.Drawing.Point(13, 192);
            this.txtChopped.Multiline = true;
            this.txtChopped.Name = "txtChopped";
            this.txtChopped.ScrollBars = System.Windows.Forms.ScrollBars.Both;
            this.txtChopped.Size = new System.Drawing.Size(659, 173);
            this.txtChopped.TabIndex = 1;
            // 
            // btnChop
            // 
            this.btnChop.Location = new System.Drawing.Point(305, 371);
            this.btnChop.Name = "btnChop";
            this.btnChop.Size = new System.Drawing.Size(75, 23);
            this.btnChop.TabIndex = 2;
            this.btnChop.Text = "&Chop";
            this.btnChop.UseVisualStyleBackColor = true;
            this.btnChop.Click += new System.EventHandler(this.btnChop_Click);
            // 
            // nudMaxConsec
            // 
            this.nudMaxConsec.Location = new System.Drawing.Point(679, 192);
            this.nudMaxConsec.Name = "nudMaxConsec";
            this.nudMaxConsec.Size = new System.Drawing.Size(54, 20);
            this.nudMaxConsec.TabIndex = 3;
            // 
            // frmCUT
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(738, 405);
            this.Controls.Add(this.nudMaxConsec);
            this.Controls.Add(this.btnChop);
            this.Controls.Add(this.txtChopped);
            this.Controls.Add(this.txtOrig);
            this.Name = "frmCUT";
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "C.U.T";
            ((System.ComponentModel.ISupportInitialize)(this.nudMaxConsec)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.TextBox txtOrig;
        private System.Windows.Forms.TextBox txtChopped;
        private System.Windows.Forms.Button btnChop;
        private System.Windows.Forms.NumericUpDown nudMaxConsec;
    }
}

