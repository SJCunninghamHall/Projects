namespace PoCW17
{
    partial class Form1
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
            this.btnChop = new System.Windows.Forms.Button();
            this.txtOrig = new System.Windows.Forms.TextBox();
            this.txtChopped = new System.Windows.Forms.TextBox();
            this.SuspendLayout();
            // 
            // btnChop
            // 
            this.btnChop.Location = new System.Drawing.Point(363, 415);
            this.btnChop.Name = "btnChop";
            this.btnChop.Size = new System.Drawing.Size(75, 23);
            this.btnChop.TabIndex = 0;
            this.btnChop.Text = "&Chop";
            this.btnChop.UseVisualStyleBackColor = true;
            // 
            // txtOrig
            // 
            this.txtOrig.Location = new System.Drawing.Point(12, 12);
            this.txtOrig.Multiline = true;
            this.txtOrig.Name = "txtOrig";
            this.txtOrig.ScrollBars = System.Windows.Forms.ScrollBars.Both;
            this.txtOrig.Size = new System.Drawing.Size(776, 177);
            this.txtOrig.TabIndex = 1;
            // 
            // txtChopped
            // 
            this.txtChopped.Location = new System.Drawing.Point(12, 195);
            this.txtChopped.Multiline = true;
            this.txtChopped.Name = "txtChopped";
            this.txtChopped.ScrollBars = System.Windows.Forms.ScrollBars.Both;
            this.txtChopped.Size = new System.Drawing.Size(776, 177);
            this.txtChopped.TabIndex = 2;
            // 
            // Form1
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(800, 450);
            this.Controls.Add(this.txtChopped);
            this.Controls.Add(this.txtOrig);
            this.Controls.Add(this.btnChop);
            this.Name = "Form1";
            this.Text = "Form1";
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Button btnChop;
        private System.Windows.Forms.TextBox txtOrig;
        private System.Windows.Forms.TextBox txtChopped;
    }
}

