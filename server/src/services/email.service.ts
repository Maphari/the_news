import dotenv from "dotenv";
import fs from "fs/promises";
import path from "path";
import handlebars from "handlebars";
import nodemailer, { Transport } from "nodemailer";
import SMTPTransport from "nodemailer/lib/smtp-transport";

dotenv.config();

export class EmailService {
  private googleEmail: String;
  private googlePassword: string;
  private googleHost: string;
  private googlePort: number;
  private isSecure: boolean = true;
  private templateCache: Map<any, any>;

  public constructor() {
    this.googleEmail = String(process.env.GOOGLE_APP_EMAIL);
    this.googlePassword = String(process.env.GOOGLE_APP_PASSWORD);
    this.googleHost = String(process.env.GOOGLE_APP_HOST);
    this.googlePort = Number(process.env.GOOGLE_APP_PORT);
    this.templateCache = new Map();
  }

  public async loadTemplate(templateName: string) {
    if (this.templateCache.has(templateName)) {
      return this.templateCache.get(templateName);
    }

    const templatePath = path.join(
      process.cwd(),
      "templates",
      `${templateName}.hbs`
    );

    const templateSource = await fs.readFile(templatePath, "utf8");
    const compiled = handlebars.compile(templateSource);

    this.templateCache.set(templateName, compiled);
    return compiled;
  }

  public async sendOTP(email: string, name: string, otp: string) {
    const template = await this.loadTemplate("otp.template");

    const html = template({
      name: name || "User",
      otp: otp,
      expiryMinutes: 10,
      currentYear: new Date().getFullYear(),
      companyName: "The news",
      supportEmail: "support@thenews.com",
      companyAddress: "123 Business Street, City, State 12345",
    });

    return await this.getNodeMailerTransport().sendMail({
      from: process.env.EMAIL_USER,
      to: email,
      subject: "🔐 Your Verification Code",
      html: html,
    });
  }

  async sendWelcome(email: string, name: string) {
    const template = await this.loadTemplate("welcome.email");

    const html = template({
      name: name,
      currentYear: new Date().getFullYear(),
      companyName: "The news",
    });

    return await this.getNodeMailerTransport().sendMail({
      from: process.env.EMAIL_USER,
      to: email,
      subject: "🎉 Welcome to Our Platform!",
      html: html,
    });
  }

  public clearCache() {
    this.templateCache.clear();
  }

  private getNodeMailerTransport() {
    return nodemailer.createTransport({
      host: this.googleHost,
      port: this.googlePort,
      secure: this.isSecure,
      auth: { user: this.googleEmail, pass: this.googlePassword },
    } as SMTPTransport.Options);
  }
}
